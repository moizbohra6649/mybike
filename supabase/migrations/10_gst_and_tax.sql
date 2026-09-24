-- ============================================================================
-- MYBIKE Dealership Management System
-- Migration 10: GST & Tax Module
-- Configurable GST Rates, Tax Calculation Engine, GSTR-1, GSTR-3B,
-- Input Tax Credit (ITC) and Statutory Reconciliation
-- ============================================================================

-- 1. GST Tax Rates Master Table
CREATE TABLE IF NOT EXISTS public.gst_tax_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_name VARCHAR(100) NOT NULL,
    hsn_sac_code VARCHAR(20) NOT NULL,
    gst_rate NUMERIC(5, 2) NOT NULL CHECK (gst_rate >= 0),
    cgst_rate NUMERIC(5, 2) NOT NULL CHECK (cgst_rate >= 0),
    sgst_rate NUMERIC(5, 2) NOT NULL CHECK (sgst_rate >= 0),
    igst_rate NUMERIC(5, 2) NOT NULL CHECK (igst_rate >= 0),
    cess_rate NUMERIC(5, 2) NOT NULL DEFAULT 0.00 CHECK (cess_rate >= 0),
    category VARCHAR(50) NOT NULL CHECK (category IN ('vehicle_ice', 'vehicle_ev', 'spare_parts', 'service_labor', 'accessories', 'documentation', 'other')),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for tax rates
CREATE INDEX IF NOT EXISTS idx_gst_rates_hsn ON public.gst_tax_rates(hsn_sac_code);
CREATE INDEX IF NOT EXISTS idx_gst_rates_category ON public.gst_tax_rates(category);
CREATE INDEX IF NOT EXISTS idx_gst_rates_active ON public.gst_tax_rates(is_active);

-- Seed Initial Statutory Dealership GST Rates
INSERT INTO public.gst_tax_rates (
    id, tax_name, hsn_sac_code, gst_rate, cgst_rate, sgst_rate, igst_rate, cess_rate, category, description, is_active, effective_from
) VALUES 
(
    'a1000000-0000-0000-0000-000000000001',
    'Petrol Motorcycles & Scooters (ICE)',
    '8711',
    28.00, 14.00, 14.00, 28.00, 0.00,
    'vehicle_ice',
    'Standard statutory 28% GST for internal combustion engine two-wheelers (CGST 14% + SGST 14% or IGST 28%)',
    true, '2017-07-01'
),
(
    'a1000000-0000-0000-0000-000000000002',
    'Electric Two-Wheelers (EV)',
    '8711',
    5.00, 2.50, 2.50, 5.00, 0.00,
    'vehicle_ev',
    'Concessional 5% green GST for battery electric motorcycles and scooters (CGST 2.5% + SGST 2.5% or IGST 5%)',
    true, '2019-08-01'
),
(
    'a1000000-0000-0000-0000-000000000003',
    'Genuine Two-Wheeler Spare Parts',
    '8714',
    18.00, 9.00, 9.00, 18.00, 0.00,
    'spare_parts',
    'Standard 18% GST for motorcycle spare parts, brake pads, filters, and mechanical components',
    true, '2017-07-01'
),
(
    'a1000000-0000-0000-0000-000000000004',
    'Automotive Accessories & Riding Gear',
    '8714',
    28.00, 14.00, 14.00, 28.00, 0.00,
    'accessories',
    'Special 28% GST for styling kits, custom exhausts, and premium riding gear',
    true, '2017-07-01'
),
(
    'a1000000-0000-0000-0000-000000000005',
    'Workshop Service & Maintenance Labor',
    '9987',
    18.00, 9.00, 9.00, 18.00, 0.00,
    'service_labor',
    'Standard 18% GST for vehicle repair, servicing, periodic maintenance labor (SAC 998729)',
    true, '2017-07-01'
),
(
    'a1000000-0000-0000-0000-000000000006',
    'Showroom Documentation & Facilitation',
    '9971',
    18.00, 9.00, 9.00, 18.00, 0.00,
    'documentation',
    '18% GST on dealership loan processing assistance and handling fees',
    true, '2017-07-01'
)
ON CONFLICT (id) DO NOTHING;

-- 2. GST Filing Periods & Monthly Return Headers
CREATE TABLE IF NOT EXISTS public.gst_filing_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID NOT NULL REFERENCES public.showrooms(id) ON DELETE RESTRICT,
    filing_period VARCHAR(10) NOT NULL, -- e.g. "2026-09"
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'computed', 'filed')),
    
    -- Outward Supplies (Output Liability)
    total_outward_taxable NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_output_cgst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_output_sgst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_output_igst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_output_cess NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    
    -- Inward Supplies (Input Tax Credit - ITC)
    total_inward_taxable NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_itc_cgst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_itc_sgst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_itc_igst NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    total_itc_cess NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    
    -- Net Liability & Settlement
    net_tax_payable NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    tax_paid_cash NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    tax_paid_itc NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    
    -- Filing Metadata
    gstr1_arn VARCHAR(50), -- Application Reference Number
    gstr3b_arn VARCHAR(50),
    filed_at TIMESTAMPTZ,
    filed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    UNIQUE (showroom_id, filing_period)
);

CREATE INDEX IF NOT EXISTS idx_gst_filing_showroom ON public.gst_filing_periods(showroom_id);
CREATE INDEX IF NOT EXISTS idx_gst_filing_period ON public.gst_filing_periods(filing_period);
CREATE INDEX IF NOT EXISTS idx_gst_filing_status ON public.gst_filing_periods(status);

-- 3. Row Level Security (RLS) Policies
ALTER TABLE public.gst_tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gst_filing_periods ENABLE ROW LEVEL SECURITY;

-- Read policy for tax rates (all authenticated users can read tax slabs)
CREATE POLICY "Allow authenticated read on gst_tax_rates"
    ON public.gst_tax_rates FOR SELECT
    TO authenticated
    USING (true);

-- Manage policy for tax rates (finance managers and admin)
CREATE POLICY "Allow admin manage on gst_tax_rates"
    ON public.gst_tax_rates FOR ALL
    TO authenticated
    USING (
        public.is_admin() OR public.has_permission(auth.uid(), 'settings', 'edit')
    );

-- Showroom isolation for filing periods
CREATE POLICY "Showroom isolation for gst_filing_periods"
    ON public.gst_filing_periods FOR ALL
    TO authenticated
    USING (
        public.is_admin()
        OR showroom_id IN (SELECT get_user_showroom_ids(auth.uid()))
    );
