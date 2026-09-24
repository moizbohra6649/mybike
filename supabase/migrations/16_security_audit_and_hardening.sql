-- =====================================================================
-- Migration 16: Security Audit & Hardening
-- MYBIKE Enterprise Multi-Showroom Two-Wheeler ERP
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Storage Buckets Creation & Security Configuration
-- ---------------------------------------------------------------------

-- Create private storage buckets for dealership operational documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('dealership-documents', 'dealership-documents', false, 15728640, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp']),
  ('customer-kyc', 'customer-kyc', false, 10485760, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
  ('vehicle-media', 'vehicle-media', false, 20971520, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('exports', 'exports', false, 26214400, ARRAY['application/pdf', 'application/vnd.ms-excel', 'text/csv', 'application/xml'])
ON CONFLICT (id) DO UPDATE SET 
  public = false,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ---------------------------------------------------------------------
-- 2. Storage Bucket Row-Level Security Policies (Tenant Scoped)
-- ---------------------------------------------------------------------

-- Policy: Allow authenticated users to view files in their assigned showroom folders
DROP POLICY IF EXISTS "Authenticated users can read authorized showroom objects" ON storage.objects;
CREATE POLICY "Authenticated users can read authorized showroom objects"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id IN ('dealership-documents', 'customer-kyc', 'vehicle-media', 'exports')
    AND (
      -- Super admin can access all buckets and folders
      (SELECT is_super_admin(auth.uid()))
      OR
      -- Path structure is [showroom_id]/[category]/[filename]
      (storage.foldername(name))[1] IN (SELECT get_user_showroom_ids(auth.uid())::text)
    )
  );

-- Policy: Allow authenticated users to upload only to their assigned showroom folders
DROP POLICY IF EXISTS "Authenticated users can upload to authorized showroom objects" ON storage.objects;
CREATE POLICY "Authenticated users can upload to authorized showroom objects"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id IN ('dealership-documents', 'customer-kyc', 'vehicle-media', 'exports')
    AND (
      (SELECT is_super_admin(auth.uid()))
      OR
      (storage.foldername(name))[1] IN (SELECT get_user_showroom_ids(auth.uid())::text)
    )
  );

-- Policy: Restrict update / delete to managers, compliance officers, and admins
DROP POLICY IF EXISTS "Authorized managers and admins can delete or update objects" ON storage.objects;
CREATE POLICY "Authorized managers and admins can delete or update objects"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id IN ('dealership-documents', 'customer-kyc', 'vehicle-media', 'exports')
    AND (
      (SELECT is_super_admin(auth.uid()))
      OR
      (
        (SELECT has_permission('documents', 'delete'))
        AND (storage.foldername(name))[1] IN (SELECT get_user_showroom_ids(auth.uid())::text)
      )
    )
  );

-- ---------------------------------------------------------------------
-- 3. Revocation of Public/Anonymous Access on Sensitive Financial Tables
-- ---------------------------------------------------------------------

REVOKE ALL ON public.finance_vouchers FROM anon, public;
REVOKE ALL ON public.journal_entries FROM anon, public;
REVOKE ALL ON public.journal_entry_lines FROM anon, public;
REVOKE ALL ON public.chart_of_accounts FROM anon, public;
REVOKE ALL ON public.sales_invoices FROM anon, public;
REVOKE ALL ON public.payment_receipts FROM anon, public;
REVOKE ALL ON public.audit_logs FROM anon, public;
REVOKE ALL ON public.approval_requests FROM anon, public;
REVOKE ALL ON public.dealership_documents FROM anon, public;

-- Grant access strictly to authenticated role
GRANT SELECT, INSERT, UPDATE ON public.finance_vouchers TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.journal_entries TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.journal_entry_lines TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.chart_of_accounts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.sales_invoices TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.payment_receipts TO authenticated;
GRANT SELECT, INSERT ON public.audit_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.approval_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dealership_documents TO authenticated;

-- ---------------------------------------------------------------------
-- 4. Multi-Tenant Stored Procedures & Boundary Checks
-- ---------------------------------------------------------------------

-- Function to verify if a user has access to a specific showroom
CREATE OR REPLACE FUNCTION public.is_user_authorized_for_showroom(user_uuid UUID, target_showroom_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Super admin has universal access
  IF public.is_super_admin(user_uuid) THEN
    RETURN TRUE;
  END IF;

  -- Check user showroom assignments
  RETURN EXISTS (
    SELECT 1 FROM public.user_showrooms
    WHERE user_id = user_uuid AND showroom_id = target_showroom_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate cross-showroom inventory transfer authorization
CREATE OR REPLACE FUNCTION public.is_transfer_authorized(
  user_uuid UUID,
  source_showroom_id UUID,
  dest_showroom_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  IF public.is_super_admin(user_uuid) THEN
    RETURN TRUE;
  END IF;

  -- User must have access to either the source showroom or inventory management permission
  RETURN public.is_user_authorized_for_showroom(user_uuid, source_showroom_id)
     AND public.has_permission('inventory', 'transfer');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
