-- ============================================================================
-- MYBIKE ERP — Purchase Order Management
-- Migration: 18_purchase_management.sql
-- ============================================================================
-- The `purchases` module was already referenced by the permission seed
-- (02_seed_data.sql), the navigation sidebar and the procurement analytics
-- (PurchaseDashboardData.pendingOrdersCount / supplierPayablesTotal), but no
-- purchase table ever existed. This adds purchase orders and their line items.
--
-- Vehicle lines are received into stock through the existing inventory inward
-- path (public.inventory_vehicles + stock_movements), so no duplicate stock
-- table is introduced here — items only track how much of each line arrived.

-- 1. Purchase Orders
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID NOT NULL REFERENCES public.showrooms(id) ON DELETE RESTRICT,
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE RESTRICT,
    po_number VARCHAR(30) NOT NULL, -- e.g. "IND-MUM-PO-00042"
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,

    -- 'new_vehicle', 'spare_part', 'accessory', 'riding_gear', 'service'
    purchase_category VARCHAR(30) NOT NULL DEFAULT 'spare_part'
        CHECK (purchase_category IN ('new_vehicle', 'spare_part', 'accessory', 'riding_gear', 'service')),

    -- Amounts are computed from the line items on save.
    subtotal NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    other_charges NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'unpaid'
        CHECK (payment_status IN ('unpaid', 'partial', 'paid')),

    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'partial', 'received', 'cancelled')),
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A PO number is unique within its branch. Also declared plainly because
-- showroom_id is NOT NULL here, so no partial index is needed.
ALTER TABLE public.purchase_orders
    DROP CONSTRAINT IF EXISTS uq_purchase_order_number;
ALTER TABLE public.purchase_orders
    ADD CONSTRAINT uq_purchase_order_number UNIQUE (showroom_id, po_number);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_showroom
    ON public.purchase_orders(showroom_id, status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier
    ON public.purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_date
    ON public.purchase_orders(order_date DESC);

CREATE TRIGGER trigger_purchase_orders_updated_at
    BEFORE UPDATE ON public.purchase_orders
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- 2. Purchase Order Line Items
CREATE TABLE IF NOT EXISTS public.purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL DEFAULT 1,
    item_type VARCHAR(30) NOT NULL DEFAULT 'spare_part'
        -- Same vocabulary as purchase_category: the form picks both from one list.
        CHECK (item_type IN ('new_vehicle', 'spare_part', 'accessory', 'riding_gear', 'service')),

    -- Only set for vehicle lines; the variant and colour to inward on receipt.
    variant_id UUID REFERENCES public.vehicle_variants(id) ON DELETE SET NULL,
    color_id UUID REFERENCES public.vehicle_colors(id) ON DELETE SET NULL,

    description VARCHAR(200) NOT NULL,
    hsn_code VARCHAR(10),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    received_quantity INTEGER NOT NULL DEFAULT 0 CHECK (received_quantity >= 0),
    unit_price NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 18.00,
    line_total NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_order_items_order
    ON public.purchase_order_items(purchase_order_id);

-- Row Level Security
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "purchase_orders_select_policy"
ON public.purchase_orders FOR SELECT
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'view') OR
    showroom_id IN (
        SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
    )
);

CREATE POLICY "purchase_orders_insert_policy"
ON public.purchase_orders FOR INSERT
WITH CHECK (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'create')
);

-- Approval flips a PO from draft to sent, so approve also grants update.
CREATE POLICY "purchase_orders_update_policy"
ON public.purchase_orders FOR UPDATE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'edit') OR
    public.has_permission(auth.uid(), 'purchases', 'approve')
);

CREATE POLICY "purchase_orders_delete_policy"
ON public.purchase_orders FOR DELETE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'delete')
);

ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;

-- Items are reachable only through an order the caller can already see, so
-- these policies mirror the parent's permission checks rather than repeating
-- the showroom list on every row.
CREATE POLICY "purchase_order_items_select_policy"
ON public.purchase_order_items FOR SELECT
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'view')
);

CREATE POLICY "purchase_order_items_insert_policy"
ON public.purchase_order_items FOR INSERT
WITH CHECK (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'create') OR
    public.has_permission(auth.uid(), 'purchases', 'edit')
);

CREATE POLICY "purchase_order_items_update_policy"
ON public.purchase_order_items FOR UPDATE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'edit') OR
    public.has_permission(auth.uid(), 'purchases', 'approve')
);

CREATE POLICY "purchase_order_items_delete_policy"
ON public.purchase_order_items FOR DELETE
USING (
    public.is_admin() OR
    public.has_permission(auth.uid(), 'purchases', 'delete') OR
    public.has_permission(auth.uid(), 'purchases', 'edit')
);
