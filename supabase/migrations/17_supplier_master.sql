-- ============================================================================
-- MYBIKE ERP — Supplier / Vendor Master
-- Migration: 17_supplier_master.sql
-- ============================================================================
-- The `suppliers` module was already referenced by the permission seed
-- (02_seed_data.sql), the navigation sidebar and the procurement analytics,
-- but its table was never created — so the section had no backing store.
-- Vendors here are OEMs, spare-part distributors, accessory and riding-gear
-- dealers, and service vendors.

CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID REFERENCES public.showrooms(id) ON DELETE SET NULL, -- NULL = shared across every branch
    code VARCHAR(30) NOT NULL,
    name VARCHAR(200) NOT NULL,
    supplier_type VARCHAR(30) NOT NULL DEFAULT 'spare_parts', -- 'oem', 'spare_parts', 'accessories', 'service', 'other'
    contact_person VARCHAR(120),
    phone VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    email VARCHAR(150),
    address TEXT,
    city VARCHAR(80),
    state VARCHAR(80),
    pincode VARCHAR(10),
    gstin VARCHAR(15),
    pan VARCHAR(10),
    bank_name VARCHAR(120),
    bank_account_number VARCHAR(40),
    bank_ifsc VARCHAR(11),
    payment_terms_days INTEGER NOT NULL DEFAULT 30,
    credit_limit DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    opening_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A vendor code is unique per branch, and unique across the shared (NULL
-- showroom) namespace. Same partial-index shape as public.settings, because a
-- plain UNIQUE(showroom_id, code) treats every NULL as distinct and would let
-- duplicate shared codes through.
CREATE UNIQUE INDEX IF NOT EXISTS uq_supplier_code_showroom
    ON public.suppliers (showroom_id, code) WHERE showroom_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_supplier_code_global
    ON public.suppliers (code) WHERE showroom_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_suppliers_showroom ON public.suppliers(showroom_id, is_active);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers(name);
CREATE INDEX IF NOT EXISTS idx_suppliers_gstin ON public.suppliers(gstin);

CREATE TRIGGER trigger_suppliers_updated_at
    BEFORE UPDATE ON public.suppliers
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Row Level Security
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_select_policy"
ON public.suppliers FOR SELECT
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'suppliers', 'view') OR
    showroom_id IS NULL OR
    showroom_id IN (
        SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
    )
);

CREATE POLICY "suppliers_insert_policy"
ON public.suppliers FOR INSERT
WITH CHECK (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'suppliers', 'create')
);

CREATE POLICY "suppliers_update_policy"
ON public.suppliers FOR UPDATE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'suppliers', 'edit')
);

CREATE POLICY "suppliers_delete_policy"
ON public.suppliers FOR DELETE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'suppliers', 'delete')
);
