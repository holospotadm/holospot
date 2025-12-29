-- ============================================================================
-- TABELA: comments
-- ============================================================================

CREATE TABLE public.comments (created_at timestamp with time zone DEFAULT now(), id uuid NOT NULL DEFAULT gen_random_uuid(), post_id uuid, user_id uuid, content text NOT NULL);
