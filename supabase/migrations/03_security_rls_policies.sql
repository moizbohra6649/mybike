-- ============================================================================
-- MYBIKE ERP — Phase 4: Row Level Security (RLS) & Security Functions
-- ============================================================================
-- Description: Establishes complete RLS policies ensuring showroom isolation,
--              role-based security, and defense-in-depth across all core tables.
-- ============================================================================

-- ============================================================================
-- 1. Security Definer Helper Functions
-- ============================================================================

-- Check if user is a Super Admin
CREATE OR REPLACE FUNCTION public.is_super_admin(p_user_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_user_id
          AND r.name = 'super_admin'
          AND ur.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user has a specific role
CREATE OR REPLACE FUNCTION public.has_role(p_user_id UUID, p_role_name VARCHAR)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.roles r ON ur.role_id = r.id
        WHERE ur.user_id = p_user_id
          AND r.name = p_role_name
          AND ur.is_active = true
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user has a specific module-action permission
CREATE OR REPLACE FUNCTION public.has_permission(p_user_id UUID, p_module VARCHAR, p_action VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super Admin has universal access
    IF public.is_super_admin(p_user_id) THEN
        RETURN true;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.user_roles ur
        JOIN public.role_permissions rp ON ur.role_id = rp.role_id
        JOIN public.permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = p_user_id
          AND ur.is_active = true
          AND p.module = p_module
          AND (p.action = p_action OR p.action = '*')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current authenticated user has a specific module-action permission (2-arg convenience overload)
CREATE OR REPLACE FUNCTION public.has_permission(p_module VARCHAR, p_action VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.has_permission(auth.uid(), p_module, p_action);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current authenticated user is an admin or super admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT public.is_super_admin(auth.uid()) OR public.has_role(auth.uid(), 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user has access to a specific showroom
CREATE OR REPLACE FUNCTION public.user_has_showroom_access(p_user_id UUID, p_showroom_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Super Admin and Admin have access across all showrooms
    IF public.is_super_admin(p_user_id) OR public.has_role(p_user_id, 'admin') THEN
        RETURN true;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.user_showrooms us
        WHERE us.user_id = p_user_id
          AND us.showroom_id = p_showroom_id
          AND us.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- 2. Enable Row Level Security on All Core Tables
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.showrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_showrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. RLS Policies: Profiles
-- ============================================================================

-- Users can read their own profile; Super Admin and Admin can read all profiles
CREATE POLICY "profiles_select_policy"
ON public.profiles FOR SELECT
TO authenticated
USING (
    auth.uid() = id
    OR public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

-- Users can update their own profile; Admins can update any profile
CREATE POLICY "profiles_update_policy"
ON public.profiles FOR UPDATE
TO authenticated
USING (
    auth.uid() = id
    OR public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
)
WITH CHECK (
    auth.uid() = id
    OR public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

-- ============================================================================
-- 4. RLS Policies: Showrooms
-- ============================================================================

-- Users see only assigned showrooms; Super Admin/Admin see all
CREATE POLICY "showrooms_select_policy"
ON public.showrooms FOR SELECT
TO authenticated
USING (
    public.user_has_showroom_access(auth.uid(), id)
);

-- Only Super Admin can insert new showrooms
CREATE POLICY "showrooms_insert_policy"
ON public.showrooms FOR INSERT
TO authenticated
WITH CHECK (
    public.is_super_admin(auth.uid())
);

-- Super Admin or Showroom Manager (assigned) can update showroom details
CREATE POLICY "showrooms_update_policy"
ON public.showrooms FOR UPDATE
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR (public.has_role(auth.uid(), 'showroom_manager') AND public.user_has_showroom_access(auth.uid(), id))
)
WITH CHECK (
    public.is_super_admin(auth.uid())
    OR (public.has_role(auth.uid(), 'showroom_manager') AND public.user_has_showroom_access(auth.uid(), id))
);

-- Only Super Admin can deactivate/delete showrooms
CREATE POLICY "showrooms_delete_policy"
ON public.showrooms FOR DELETE
TO authenticated
USING (
    public.is_super_admin(auth.uid())
);

-- ============================================================================
-- 5. RLS Policies: Roles & Permissions
-- ============================================================================

-- All authenticated users can view roles and permissions (needed for client permission checks)
CREATE POLICY "roles_select_policy"
ON public.roles FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "permissions_select_policy"
ON public.permissions FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "role_permissions_select_policy"
ON public.role_permissions FOR SELECT
TO authenticated
USING (true);

-- Only Super Admin can manage roles and permissions
CREATE POLICY "roles_admin_manage_policy"
ON public.roles FOR ALL
TO authenticated
USING (public.is_super_admin(auth.uid()))
WITH CHECK (public.is_super_admin(auth.uid()));

CREATE POLICY "role_permissions_admin_manage_policy"
ON public.role_permissions FOR ALL
TO authenticated
USING (public.is_super_admin(auth.uid()))
WITH CHECK (public.is_super_admin(auth.uid()));

-- ============================================================================
-- 6. RLS Policies: User Roles & User Showrooms
-- ============================================================================

-- Users can view their own role assignments; Admins can view all
CREATE POLICY "user_roles_select_policy"
ON public.user_roles FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
    OR public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

CREATE POLICY "user_roles_manage_policy"
ON public.user_roles FOR ALL
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
)
WITH CHECK (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

-- Users can view their own showroom assignments; Admins can view all
CREATE POLICY "user_showrooms_select_policy"
ON public.user_showrooms FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
    OR public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

CREATE POLICY "user_showrooms_manage_policy"
ON public.user_showrooms FOR ALL
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
)
WITH CHECK (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'admin')
);

-- ============================================================================
-- 7. RLS Policies: Financial Years
-- ============================================================================

-- All authenticated users can view FY definitions
CREATE POLICY "financial_years_select_policy"
ON public.financial_years FOR SELECT
TO authenticated
USING (true);

-- Super Admin and Accountants can manage FY
CREATE POLICY "financial_years_manage_policy"
ON public.financial_years FOR ALL
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'accountant')
)
WITH CHECK (
    public.is_super_admin(auth.uid())
    OR public.has_role(auth.uid(), 'accountant')
);

-- ============================================================================
-- 8. RLS Policies: Invoice Sequences
-- ============================================================================

CREATE POLICY "invoice_sequences_select_policy"
ON public.invoice_sequences FOR SELECT
TO authenticated
USING (
    public.user_has_showroom_access(auth.uid(), showroom_id)
);

CREATE POLICY "invoice_sequences_manage_policy"
ON public.invoice_sequences FOR ALL
TO authenticated
USING (
    public.user_has_showroom_access(auth.uid(), showroom_id)
)
WITH CHECK (
    public.user_has_showroom_access(auth.uid(), showroom_id)
);

-- ============================================================================
-- 9. RLS Policies: Audit Logs (IMMUTABLE)
-- ============================================================================

-- Admins can view audit logs for their showrooms; Super Admin can view all
CREATE POLICY "audit_logs_select_policy"
ON public.audit_logs FOR SELECT
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR (
        public.has_role(auth.uid(), 'admin')
        AND (showroom_id IS NULL OR public.user_has_showroom_access(auth.uid(), showroom_id))
    )
);

-- Any authenticated action can write to audit log
CREATE POLICY "audit_logs_insert_policy"
ON public.audit_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- NO UPDATE or DELETE on audit logs (Strict immutability)
-- (By omitting UPDATE and DELETE policies, PostgreSQL rejects all attempts)

-- ============================================================================
-- 10. RLS Policies: Settings
-- ============================================================================

-- Users can view settings for global or their assigned showrooms
CREATE POLICY "settings_select_policy"
ON public.settings FOR SELECT
TO authenticated
USING (
    showroom_id IS NULL
    OR public.user_has_showroom_access(auth.uid(), showroom_id)
);

-- Only Admins can modify settings
CREATE POLICY "settings_manage_policy"
ON public.settings FOR ALL
TO authenticated
USING (
    public.is_super_admin(auth.uid())
    OR (
        public.has_role(auth.uid(), 'admin')
        AND showroom_id IS NOT NULL
        AND public.user_has_showroom_access(auth.uid(), showroom_id)
    )
)
WITH CHECK (
    public.is_super_admin(auth.uid())
    OR (
        public.has_role(auth.uid(), 'admin')
        AND showroom_id IS NOT NULL
        AND public.user_has_showroom_access(auth.uid(), showroom_id)
    )
);
