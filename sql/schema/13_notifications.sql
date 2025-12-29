-- ============================================================================
-- TABELA: notifications
-- ============================================================================

CREATE TABLE public.notifications (id uuid NOT NULL DEFAULT gen_random_uuid(), post_id uuid, priority integer DEFAULT 1, group_data jsonb, group_count integer DEFAULT 1, group_key text, created_at timestamp with time zone DEFAULT now(), read boolean DEFAULT false, message text NOT NULL, type text NOT NULL, from_user_id uuid, user_id uuid NOT NULL);
