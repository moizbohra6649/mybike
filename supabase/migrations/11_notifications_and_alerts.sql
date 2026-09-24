-- ============================================================================
-- Migration 11: Notifications, FCM Device Tokens & Realtime Alert Engine
-- MYBIKE — Multi-Showroom Bike Dealership Management & Accounting ERP
-- ============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Notifications Table
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    showroom_id UUID REFERENCES public.showrooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    target_role VARCHAR(50), -- e.g. 'store_manager', 'inventory_manager', 'sales_executive', 'accountant', NULL for user-specific
    category VARCHAR(50) NOT NULL CHECK (category IN ('inventory', 'sales', 'finance', 'booking', 'gst', 'system', 'transfer')),
    priority VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_route VARCHAR(255), -- Deep link route (e.g. '/sales/inv-101', '/inventory/transfer', '/reports/gstr1')
    data JSONB DEFAULT '{}'::jsonb, -- Additional payload metadata (entity IDs, amounts, counts)
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_showroom_id ON public.notifications(showroom_id);
CREATE INDEX IF NOT EXISTS idx_notifications_category ON public.notifications(category);
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON public.notifications(priority);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Notification Preferences Table
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    inventory_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    sales_milestones BOOLEAN NOT NULL DEFAULT TRUE,
    finance_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    gst_reminders BOOLEAN NOT NULL DEFAULT TRUE,
    system_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sound_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ────────────────────────────────────────────────────────────────────────────
-- 3. FCM Device Tokens Table
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fcm_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(30) NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON public.fcm_device_tokens(user_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Row Level Security (RLS)
-- ────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_device_tokens ENABLE ROW LEVEL SECURITY;

-- Notifications Select Policy
CREATE POLICY "Users view own or showroom broadcast notifications"
    ON public.notifications FOR SELECT
    USING (
        auth.uid() = user_id 
        OR (
            user_id IS NULL 
            AND (
                showroom_id IS NULL
                OR showroom_id IN (
                    SELECT showroom_id FROM public.user_showrooms WHERE user_id = auth.uid()
                )
            )
        )
    );

-- Notifications Update Policy (Marking Read)
CREATE POLICY "Users update own notifications read status"
    ON public.notifications FOR UPDATE
    USING (
        auth.uid() = user_id 
        OR user_id IS NULL
    )
    WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL
    );

-- Notification Preferences Policies
CREATE POLICY "Users view and manage own notification preferences"
    ON public.notification_preferences FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- FCM Device Tokens Policies
CREATE POLICY "Users manage own FCM device tokens"
    ON public.fcm_device_tokens FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Seed Realtime Alert Notifications for Showroom Operations
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO public.notifications (
    id,
    showroom_id,
    user_id,
    target_role,
    category,
    priority,
    title,
    message,
    action_route,
    data,
    is_read,
    created_at
) VALUES
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c50',
    NULL,
    NULL,
    'inventory_manager',
    'inventory',
    'urgent',
    'Low Stock Warning: EV Battery Pack 72V',
    'Stock for Lithium Iron Phosphate 72V battery pack is at 1 unit (reorder threshold: 3). Restock required.',
    '/inventory',
    '{"sku": "BAT-72V-LFP", "current_stock": 1, "reorder_level": 3}'::jsonb,
    FALSE,
    NOW() - INTERVAL '12 minutes'
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c51',
    NULL,
    NULL,
    'sales_executive',
    'booking',
    'high',
    'New Customer Booking Allocated',
    'Booking #BK-2026-0042 for Rahul Verma (Speedster 250 DLX) has been confirmed with Rs. 10,000 token advance.',
    '/bookings',
    '{"booking_id": "BK-2026-0042", "customer": "Rahul Verma", "advance": 10000}'::jsonb,
    FALSE,
    NOW() - INTERVAL '45 minutes'
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c52',
    NULL,
    NULL,
    'accountant',
    'finance',
    'high',
    'Overdue Receivables Alert',
    'Customer Moiz Bohra has an outstanding balance of Rs. 20,000 against Tax Invoice IND-MUM-INV-00101 exceeding 15 days.',
    '/finance/outstandings',
    '{"invoice_number": "IND-MUM-INV-00101", "balance": 20000, "overdue_days": 15}'::jsonb,
    FALSE,
    NOW() - INTERVAL '2 hours'
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c53',
    NULL,
    NULL,
    'store_manager',
    'transfer',
    'normal',
    'Stock Transfer Dispatched',
    'Stock Transfer #TR-0089 with 2 units of Activa 6G DLX dispatched from Central Depot to Mumbai Showroom.',
    '/inventory/transfer',
    '{"transfer_id": "TR-0089", "units": 2}'::jsonb,
    TRUE,
    NOW() - INTERVAL '5 hours'
),
(
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c54',
    NULL,
    NULL,
    'accountant',
    'gst',
    'urgent',
    'Statutory Reminder: GSTR-3B Monthly Return Due',
    'GSTR-3B return filing deadline for the prior tax period is approaching on the 20th. Ensure Output/ITC reconciliation.',
    '/gst/gstr-3b',
    '{"period": "Feb-2026", "due_date": "20-Mar-2026"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '1 day'
)
ON CONFLICT (id) DO NOTHING;
