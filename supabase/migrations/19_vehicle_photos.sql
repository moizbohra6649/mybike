-- ═══════════════════════════════════════════════════════════════════════
-- Migration 19: Vehicle Photo Gallery
-- Supports both inventory VIN-level photos and model catalog photos
-- ═══════════════════════════════════════════════════════════════════════

-- 1. Photo metadata table
CREATE TABLE IF NOT EXISTS public.vehicle_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Polymorphic: exactly one of these must be set
    vehicle_id UUID REFERENCES public.inventory_vehicles(id) ON DELETE CASCADE,
    model_id UUID REFERENCES public.vehicle_models(id) ON DELETE CASCADE,

    file_name VARCHAR(255) NOT NULL,
    storage_path TEXT NOT NULL,               -- path inside the storage bucket
    public_url TEXT,                          -- full public URL for display
    file_size_bytes BIGINT DEFAULT 0,
    mime_type VARCHAR(50) DEFAULT 'image/jpeg',

    photo_type VARCHAR(30) NOT NULL DEFAULT 'general'
        CHECK (photo_type IN (
            'general', 'front', 'rear', 'left', 'right',
            'dashboard', 'engine', 'chassis', 'pdi',
            'damage', 'delivery', 'marketing', 'brochure'
        )),
    caption TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_primary BOOLEAN NOT NULL DEFAULT false,

    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Constraint: exactly one FK must be set
ALTER TABLE public.vehicle_photos
    ADD CONSTRAINT chk_vehicle_photos_owner
    CHECK (
        (vehicle_id IS NOT NULL AND model_id IS NULL)
        OR
        (vehicle_id IS NULL AND model_id IS NOT NULL)
    );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vehicle_photos_vehicle ON public.vehicle_photos(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_photos_model ON public.vehicle_photos(model_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_photos_type ON public.vehicle_photos(photo_type);

-- RLS
ALTER TABLE public.vehicle_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vehicle_photos_select"
    ON public.vehicle_photos FOR SELECT
    USING (true);

CREATE POLICY "vehicle_photos_insert"
    ON public.vehicle_photos FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "vehicle_photos_delete"
    ON public.vehicle_photos FOR DELETE
    USING (auth.role() = 'authenticated');

-- 2. Supabase Storage bucket (run via Supabase dashboard or seed SQL)
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--   'vehicle-photos',
--   'vehicle-photos',
--   true,
--   5242880,  -- 5 MB
--   ARRAY['image/jpeg', 'image/png', 'image/webp']
-- )
-- ON CONFLICT (id) DO NOTHING;
