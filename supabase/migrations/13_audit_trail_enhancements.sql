-- ============================================================================
-- MYBIKE ERP — Phase 20: Audit Logs & Compliance Engine Enhancements
-- Migration: 13_audit_trail_enhancements.sql
-- ============================================================================

-- 0. is_admin() — called by the RLS policies here and in 14, 17 and 18, but it
-- was never defined, so each of those CREATE POLICY statements failed on a
-- fresh database. Defined here, ahead of its first caller, rather than in 03,
-- because 03 cannot be re-run on a database that already has its policies.
-- Same meaning as user_has_showroom_access(): super admin or admin role.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT public.is_super_admin(auth.uid()) OR public.has_role(auth.uid(), 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 1. Enhance audit_logs table with user details, human-readable record titles, and severity
ALTER TABLE public.audit_logs
    ADD COLUMN IF NOT EXISTS user_name VARCHAR(150),
    ADD COLUMN IF NOT EXISTS user_email VARCHAR(150),
    ADD COLUMN IF NOT EXISTS module VARCHAR(50),
    ADD COLUMN IF NOT EXISTS record_title VARCHAR(255),
    ADD COLUMN IF NOT EXISTS severity VARCHAR(20) DEFAULT 'info'; -- 'info', 'warning', 'critical'

-- 2. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_module ON public.audit_logs(module, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_severity ON public.audit_logs(severity);

-- 3. Stored Procedure for Unified Application-level Auditing
CREATE OR REPLACE FUNCTION public.log_audit_event(
    p_table_name VARCHAR(50),
    p_record_id UUID,
    p_action VARCHAR(20),
    p_old_data JSONB,
    p_new_data JSONB,
    p_user_id UUID,
    p_user_name VARCHAR(150),
    p_user_email VARCHAR(150),
    p_module VARCHAR(50),
    p_record_title VARCHAR(255),
    p_showroom_id UUID,
    p_severity VARCHAR(20) DEFAULT 'info',
    p_ip_address VARCHAR(45) DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_audit_id UUID;
BEGIN
    INSERT INTO public.audit_logs (
        table_name,
        record_id,
        action,
        old_data,
        new_data,
        user_id,
        user_name,
        user_email,
        module,
        record_title,
        showroom_id,
        severity,
        ip_address,
        user_agent,
        created_at
    ) VALUES (
        p_table_name,
        p_record_id,
        p_action,
        p_old_data,
        p_new_data,
        p_user_id,
        p_user_name,
        p_user_email,
        COALESCE(p_module, p_table_name),
        p_record_title,
        p_showroom_id,
        COALESCE(p_severity, 'info'),
        p_ip_address,
        p_user_agent,
        now()
    )
    RETURNING id INTO v_audit_id;

    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Audit Log RLS Policies (Read allowed for admin/managers, Insert for all authenticated users)
DROP POLICY IF EXISTS "audit_logs_select_policy" ON public.audit_logs;
CREATE POLICY "audit_logs_select_policy"
ON public.audit_logs FOR SELECT
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'audit_logs', 'view') OR
    showroom_id IS NULL OR
    showroom_id IN (
        SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "audit_logs_insert_policy" ON public.audit_logs;
CREATE POLICY "audit_logs_insert_policy"
ON public.audit_logs FOR INSERT
WITH CHECK (true);
