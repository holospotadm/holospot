-- ============================================================================
-- TABELA: reactions
-- ============================================================================

CREATE TABLE public.reactions (id uuid NOT NULL DEFAULT gen_random_uuid(), created_at timestamp with time zone DEFAULT now(), type text NOT NULL, user_id uuid, post_id uuid);
