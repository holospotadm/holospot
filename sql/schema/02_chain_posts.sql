-- ============================================================================
-- TABELA: chain_posts
-- ============================================================================

CREATE TABLE public.chain_posts (author_id uuid NOT NULL, post_id uuid NOT NULL, chain_id uuid NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid(), created_at timestamp with time zone NOT NULL DEFAULT now(), parent_post_author_id uuid);
