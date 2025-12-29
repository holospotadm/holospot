-- ============================================================================
-- TABELA: follows
-- ============================================================================

CREATE TABLE public.follows (id uuid NOT NULL DEFAULT gen_random_uuid(), follower_id uuid NOT NULL, following_id uuid NOT NULL, created_at timestamp with time zone DEFAULT now());
