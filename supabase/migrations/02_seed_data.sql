-- ============================================================================
-- MYBIKE ERP — Phase 3: Core Seed Data
-- ============================================================================
-- Description: Seeds 11 roles, permissions across ERP modules,
--              role-permission matrix, default FY 2026-27, and flagship showroom.
-- ============================================================================

-- 1. Seed Roles
INSERT INTO public.roles (name, display_name, description, is_system_role)
VALUES 
    ('super_admin', 'Super Admin', 'Full system control across all showrooms', true),
    ('admin', 'Admin', 'Business administration and reports across showrooms', true),
    ('showroom_manager', 'Showroom Manager', 'Operational control of assigned showrooms', true),
    ('sales_manager', 'Sales Manager', 'Sales team management and approvals', false),
    ('sales_executive', 'Sales Executive', 'Customer handling, quotations, and bookings', false),
    ('purchase_manager', 'Purchase Manager', 'Supplier management and purchase orders', false),
    ('inventory_manager', 'Inventory Manager', 'Stock management, receiving, and transfers', false),
    ('accountant', 'Accountant', 'General ledger, journal entries, and financial statements', false),
    ('cashier', 'Cashier', 'Receipts, cash collections, and counter payments', false),
    ('service_manager', 'Service Manager', 'Service operations and warranty processing', false),
    ('viewer', 'Viewer', 'Read-only access to authorized modules', false)
ON CONFLICT (name) DO UPDATE 
SET display_name = EXCLUDED.display_name, description = EXCLUDED.description;

-- 2. Seed Permissions across Modules
-- Modules: dashboard, showrooms, users, roles, vehicles, inventory, customers,
--          suppliers, purchases, sales, bookings, payments, expenses, accounting, reports, settings
DO $$
DECLARE
    v_modules TEXT[] := ARRAY[
        'dashboard', 'showrooms', 'users', 'roles', 'permissions',
        'vehicles', 'inventory', 'customers', 'suppliers', 'purchases',
        'sales', 'bookings', 'payments', 'expenses', 'accounting',
        'reports', 'audit_logs', 'settings', 'documents', 'notifications'
    ];
    v_actions TEXT[] := ARRAY['view', 'create', 'edit', 'delete', 'approve', 'export', 'print'];
    m TEXT;
    a TEXT;
BEGIN
    FOREACH m IN ARRAY v_modules LOOP
        FOREACH a IN ARRAY v_actions LOOP
            INSERT INTO public.permissions (module, action, description)
            VALUES (m, a, 'Permission to ' || a || ' in ' || m || ' module')
            ON CONFLICT (module, action) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- 3. Map All Permissions to Super Admin & Admin
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.name IN ('super_admin', 'admin')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Map Showroom Manager Permissions (View, Create, Edit, Approve, Export, Print on operational modules)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.name = 'showroom_manager'
  AND p.module IN ('dashboard', 'showrooms', 'vehicles', 'inventory', 'customers', 'suppliers', 'purchases', 'sales', 'bookings', 'payments', 'expenses', 'reports')
  AND p.action IN ('view', 'create', 'edit', 'approve', 'export', 'print')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Map Sales Executive Permissions (View, Create, Edit on sales, customers, bookings, vehicles)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.name = 'sales_executive'
  AND p.module IN ('dashboard', 'vehicles', 'customers', 'bookings', 'sales')
  AND p.action IN ('view', 'create', 'edit', 'print')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Map Accountant Permissions (Full access to accounting, expenses, payments, reports, ledgers)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.name = 'accountant'
  AND p.module IN ('dashboard', 'accounting', 'expenses', 'payments', 'reports')
  AND p.action IN ('view', 'create', 'edit', 'delete', 'approve', 'export', 'print')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Map Viewer Permissions (View only on non-sensitive modules)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.name = 'viewer'
  AND p.action = 'view'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 4. Seed Default Financial Year (Indian FY 2026-27: April 1, 2026 to March 31, 2027)
INSERT INTO public.financial_years (name, start_date, end_date, is_current, is_locked)
VALUES ('2026-27', '2026-04-01', '2027-03-31', true, false)
ON CONFLICT (name) DO UPDATE
SET is_current = EXCLUDED.is_current;

-- 5. Seed Flagship Showroom
INSERT INTO public.showrooms (
    name, code, address, city, state, pincode, phone, email,
    gstin, pan, bank_name, bank_account_number, bank_ifsc, bank_branch, invoice_prefix, is_active
)
VALUES (
    'MYBIKE Flagship Central',
    'IND-MAIN',
    'Plot 42, Automobile Hub, Linking Road, Bandra West',
    'Mumbai',
    'Maharashtra',
    '400050',
    '+91 98200 12345',
    'mumbai.central@mybike.com',
    '27AABCM1234F1Z5',
    'AABCM1234F',
    'HDFC Bank Ltd',
    '50200012345678',
    'HDFC0000123',
    'Bandra West Branch',
    'MBMUM',
    true
)
ON CONFLICT (code) DO NOTHING;

-- 6. Seed Global Application Settings
INSERT INTO public.settings (key, value, description)
VALUES 
    ('app_name', '"MYBIKE ERP"'::jsonb, 'Application Brand Name'),
    ('currency_code', '"INR"'::jsonb, 'Primary Currency Code'),
    ('currency_symbol', '"₹"'::jsonb, 'Currency Symbol'),
    ('default_gst_rate', '18'::jsonb, 'Default GST percentage for accessories & parts'),
    ('vehicle_gst_rate', '28'::jsonb, 'Default GST percentage for vehicles'),
    ('ev_gst_rate', '5'::jsonb, 'Concessional GST percentage for Electric Vehicles (EVs)'),
    ('support_email', '"support@mybike.com"'::jsonb, 'Dealership ERP Support Contact')
ON CONFLICT (key) WHERE showroom_id IS NULL DO UPDATE
SET value = EXCLUDED.value;
