-- ============================================================================
-- Migration 12: Dealership Document Management System (DMS)
-- MYBIKE — Multi-Showroom Bike Dealership Management & Accounting ERP
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Dealership Documents Table
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.dealership_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID REFERENCES public.showrooms(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL CHECK (entity_type IN ('customer', 'vehicle', 'booking', 'invoice', 'purchase', 'showroom', 'general')),
    entity_id VARCHAR(100) NOT NULL, -- e.g. customer_id, vin, booking_id, invoice_id
    document_category VARCHAR(50) NOT NULL CHECK (document_category IN ('kyc', 'rto_registration', 'insurance', 'warranty', 'delivery', 'purchase_invoice', 'factory_gatepass', 'hypothecation', 'puc', 'other')),
    document_type VARCHAR(80) NOT NULL, -- e.g. 'Aadhaar Card', 'PAN Card', 'Driving License', 'Form 20', 'Form 21 Sale Certificate', 'Form 22 Roadworthiness', 'RC Book', 'Insurance Policy'
    document_number VARCHAR(100), -- Unique identifier or reference (e.g. Aadhaar last 4, PAN, Policy No, Registration No)
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL, -- Size in bytes
    mime_type VARCHAR(100) NOT NULL, -- 'application/pdf', 'image/jpeg', 'image/png'
    verification_status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired')),
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMPTZ,
    rejection_reason TEXT,
    expiry_date DATE,
    uploaded_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for lightning-fast queries
CREATE INDEX IF NOT EXISTS idx_dms_showroom_id ON public.dealership_documents(showroom_id);
CREATE INDEX IF NOT EXISTS idx_dms_entity ON public.dealership_documents(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_dms_category ON public.dealership_documents(document_category);
CREATE INDEX IF NOT EXISTS idx_dms_verification ON public.dealership_documents(verification_status);
CREATE INDEX IF NOT EXISTS idx_dms_created_at ON public.dealership_documents(created_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Row Level Security (RLS)
-- ────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.dealership_documents ENABLE ROW LEVEL SECURITY;

-- Allow users to view documents matching their showroom access or global admin
CREATE POLICY "Users view documents for assigned showrooms"
    ON public.dealership_documents FOR SELECT
    USING (
        showroom_id IS NULL
        OR showroom_id IN (
            SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
        )
    );

-- Allow authenticated dealership staff to insert documents
CREATE POLICY "Staff insert documents for assigned showrooms"
    ON public.dealership_documents FOR INSERT
    WITH CHECK (
        showroom_id IS NULL
        OR showroom_id IN (
            SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
        )
    );

-- Allow staff to update documents (e.g. verification status, rejection reason)
CREATE POLICY "Staff update documents for assigned showrooms"
    ON public.dealership_documents FOR UPDATE
    USING (
        showroom_id IS NULL
        OR showroom_id IN (
            SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
        )
    );

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Seed Realistic Dealership Statutory & Customer Documents
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO public.dealership_documents (
    id,
    showroom_id,
    entity_type,
    entity_id,
    document_category,
    document_type,
    document_number,
    file_name,
    file_path,
    file_size,
    mime_type,
    verification_status,
    verified_by,
    verified_at,
    rejection_reason,
    expiry_date,
    notes,
    created_at
) VALUES
(
    'd0000001-0000-0000-0000-000000000001',
    NULL,
    'customer',
    'cust-01',
    'kyc',
    'Aadhaar Card',
    'XXXX-XXXX-9842',
    'aadhaar_moiz_bohra.pdf',
    'documents/kyc/aadhaar_moiz_bohra.pdf',
    842150,
    'application/pdf',
    'verified',
    NULL,
    NOW() - INTERVAL '2 days',
    NULL,
    NULL,
    'Customer primary identity verification verified with UIDAI mask.',
    NOW() - INTERVAL '3 days'
),
(
    'd0000001-0000-0000-0000-000000000002',
    NULL,
    'customer',
    'cust-01',
    'kyc',
    'PAN Card',
    'ABCDE1234F',
    'pan_moiz_bohra.jpg',
    'documents/kyc/pan_moiz_bohra.jpg',
    421000,
    'image/jpeg',
    'verified',
    NULL,
    NOW() - INTERVAL '2 days',
    NULL,
    NULL,
    'PAN verified against NSDL records for GST invoicing.',
    NOW() - INTERVAL '3 days'
),
(
    'd0000001-0000-0000-0000-000000000003',
    NULL,
    'vehicle',
    'MD2A12345E6789012',
    'rto_registration',
    'Form 20 (RTO Application)',
    'MH-02-2026-F20-091',
    'form20_speedster250.pdf',
    'documents/rto/form20_speedster250.pdf',
    1245000,
    'application/pdf',
    'pending',
    NULL,
    NULL,
    NULL,
    NULL,
    'Application for Registration of a Motor Vehicle signed by customer.',
    NOW() - INTERVAL '6 hours'
),
(
    'd0000001-0000-0000-0000-000000000004',
    NULL,
    'vehicle',
    'MD2A12345E6789012',
    'rto_registration',
    'Form 21 (Sale Certificate)',
    'MB-MUM-F21-0045',
    'form21_sale_certificate.pdf',
    'documents/rto/form21_sale_certificate.pdf',
    612000,
    'application/pdf',
    'verified',
    NULL,
    NOW() - INTERVAL '1 day',
    NULL,
    NULL,
    'Sale Certificate issued under Rule 47 of Central Motor Vehicles Rules.',
    NOW() - INTERVAL '1 day'
),
(
    'd0000001-0000-0000-0000-000000000005',
    NULL,
    'booking',
    'BK-2026-0042',
    'insurance',
    'Comprehensive Insurance Policy (1+5 Yr)',
    'POL-HDFC-9928172',
    'hdfc_ergo_policy.pdf',
    'documents/insurance/hdfc_ergo_policy.pdf',
    1520000,
    'application/pdf',
    'pending',
    NULL,
    NULL,
    NULL,
    '2031-03-14',
    '5 Years Third Party + 1 Year Own Damage coverage.',
    NOW() - INTERVAL '4 hours'
),
(
    'd0000001-0000-0000-0000-000000000006',
    NULL,
    'customer',
    'cust-02',
    'kyc',
    'Driving License',
    'MH02-20180048123',
    'driving_license_rahul.jpg',
    'documents/kyc/driving_license_rahul.jpg',
    512000,
    'image/jpeg',
    'rejected',
    NULL,
    NOW() - INTERVAL '5 hours',
    'Photo is blurry and address is not clearly legible. Please upload high-resolution scan.',
    '2038-08-20',
    'Re-upload requested from customer.',
    NOW() - INTERVAL '1 day'
)
ON CONFLICT (id) DO NOTHING;
