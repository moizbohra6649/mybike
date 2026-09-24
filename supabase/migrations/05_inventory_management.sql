-- ============================================================================
-- Phase 9: Inventory & Stock Management Migration
-- Vehicles as High-Value Serialized Assets (VIN, Engine, Motor, Battery Serial, PDI, Movements, Transfers)
-- ============================================================================

-- Ensure 2-argument has_permission overload and is_admin exist
CREATE OR REPLACE FUNCTION public.has_permission(p_module VARCHAR, p_action VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.has_permission(auth.uid(), p_module, p_action);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT public.is_super_admin(auth.uid()) OR public.has_role(auth.uid(), 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 1. Inventory Vehicles (Individual Serialized Units)
CREATE TABLE IF NOT EXISTS public.inventory_vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID NOT NULL REFERENCES public.showrooms(id) ON DELETE RESTRICT,
    variant_id UUID NOT NULL REFERENCES public.vehicle_variants(id) ON DELETE RESTRICT,
    color_id UUID NOT NULL REFERENCES public.vehicle_colors(id) ON DELETE RESTRICT,
    vin VARCHAR(17) NOT NULL UNIQUE, -- 17-character ISO 3779 standard VIN / Chassis Number
    engine_number VARCHAR(50), -- Petrol only
    motor_number VARCHAR(50), -- Electric EV only
    battery_serial_number VARCHAR(50), -- Electric EV only
    key_number VARCHAR(50), -- Physical key tag / key pouch number
    status VARCHAR(30) NOT NULL DEFAULT 'in_stock'
        CHECK (status IN ('in_stock', 'booked', 'allocated', 'sold', 'in_transit', 'delivered', 'damaged')),
    purchase_cost NUMERIC(12, 2) NOT NULL DEFAULT 0.0,
    received_date DATE NOT NULL DEFAULT CURRENT_DATE,
    mfg_year_month VARCHAR(10) NOT NULL DEFAULT '2026-01', -- e.g. "2026-01"
    battery_health_percentage NUMERIC(5, 2), -- EV battery health (e.g. 100.00%)
    odometer_reading_km NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    location_in_showroom VARCHAR(100) DEFAULT 'Main Display Area',
    pdi_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (pdi_status IN ('pending', 'passed', 'failed')),
    pdi_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trigger_inventory_vehicles_updated_at
    BEFORE UPDATE ON public.inventory_vehicles
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- 2. Stock Transfers (Inter-Showroom Branch Transfers)
CREATE TABLE IF NOT EXISTS public.stock_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_number VARCHAR(50) NOT NULL UNIQUE, -- e.g. "TRF-IND-MAIN-2026-0001"
    source_showroom_id UUID NOT NULL REFERENCES public.showrooms(id) ON DELETE RESTRICT,
    destination_showroom_id UUID NOT NULL REFERENCES public.showrooms(id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'in_transit', 'received', 'rejected', 'cancelled')),
    requested_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    dispatched_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    received_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    dispatched_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_diff_showrooms CHECK (source_showroom_id <> destination_showroom_id)
);

CREATE TRIGGER trigger_stock_transfers_updated_at
    BEFORE UPDATE ON public.stock_transfers
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- 3. Stock Transfer Items (VINs mapped to a transfer document)
CREATE TABLE IF NOT EXISTS public.stock_transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID NOT NULL REFERENCES public.stock_transfers(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.inventory_vehicles(id) ON DELETE RESTRICT,
    status VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'in_transit', 'received', 'rejected')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_transfer_vehicle UNIQUE (transfer_id, vehicle_id)
);

-- 4. Stock Movements (Immutable Lifecycle Audit Log)
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES public.inventory_vehicles(id) ON DELETE CASCADE,
    movement_type VARCHAR(50) NOT NULL
        CHECK (movement_type IN (
            'inward_grn',
            'transfer_dispatch',
            'transfer_receive',
            'booking_allocation',
            'booking_released',
            'sale_delivery',
            'pdi_status_update',
            'bay_location_change',
            'status_adjustment'
        )),
    from_showroom_id UUID REFERENCES public.showrooms(id) ON DELETE SET NULL,
    to_showroom_id UUID REFERENCES public.showrooms(id) ON DELETE SET NULL,
    performed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Indexes for Fast Inventory & VIN Search
CREATE INDEX IF NOT EXISTS idx_inventory_vehicles_showroom ON public.inventory_vehicles(showroom_id);
CREATE INDEX IF NOT EXISTS idx_inventory_vehicles_variant ON public.inventory_vehicles(variant_id);
CREATE INDEX IF NOT EXISTS idx_inventory_vehicles_status ON public.inventory_vehicles(status);
CREATE INDEX IF NOT EXISTS idx_inventory_vehicles_vin ON public.inventory_vehicles(vin);
CREATE INDEX IF NOT EXISTS idx_inventory_vehicles_pdi ON public.inventory_vehicles(pdi_status);

CREATE INDEX IF NOT EXISTS idx_stock_transfers_source ON public.stock_transfers(source_showroom_id);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_dest ON public.stock_transfers(destination_showroom_id);
CREATE INDEX IF NOT EXISTS idx_stock_transfers_status ON public.stock_transfers(status);

CREATE INDEX IF NOT EXISTS idx_stock_movements_vehicle ON public.stock_movements(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_type ON public.stock_movements(movement_type);

-- 6. Row Level Security (RLS)
ALTER TABLE public.inventory_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_transfer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view inventory for showrooms they have access to
CREATE POLICY "Users can view inventory in assigned showrooms"
    ON public.inventory_vehicles FOR SELECT
    TO authenticated
    USING (
        is_super_admin(auth.uid()) OR
        has_permission('inventory', 'view') OR
        showroom_id IN (SELECT get_user_showroom_ids(auth.uid()))
    );

-- Allow inventory managers and admins to manage inventory vehicles
CREATE POLICY "Admins and inventory managers can modify inventory"
    ON public.inventory_vehicles FOR ALL
    TO authenticated
    USING (
        is_super_admin(auth.uid()) OR
        has_permission('inventory', 'edit') OR
        has_permission('inventory', 'create')
    );

-- Stock transfers policies
CREATE POLICY "Users can view stock transfers"
    ON public.stock_transfers FOR SELECT
    TO authenticated
    USING (
        is_super_admin(auth.uid()) OR
        has_permission('inventory', 'view') OR
        source_showroom_id IN (SELECT get_user_showroom_ids(auth.uid())) OR
        destination_showroom_id IN (SELECT get_user_showroom_ids(auth.uid()))
    );

CREATE POLICY "Admins and inventory managers can manage transfers"
    ON public.stock_transfers FOR ALL
    TO authenticated
    USING (
        is_super_admin(auth.uid()) OR
        has_permission('inventory', 'create') OR
        has_permission('inventory', 'edit')
    );

CREATE POLICY "Users can view transfer items"
    ON public.stock_transfer_items FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Managers can update transfer items"
    ON public.stock_transfer_items FOR ALL
    TO authenticated
    USING (
        is_super_admin(auth.uid()) OR
        has_permission('inventory', 'edit')
    );

CREATE POLICY "Users can view stock movements"
    ON public.stock_movements FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Authenticated users can insert stock movements"
    ON public.stock_movements FOR INSERT
    TO authenticated
    WITH CHECK (true);
