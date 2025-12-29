-- ============================================================================
-- TABELA: chains
-- ============================================================================

CREATE TABLE public.chains (status text NOT NULL DEFAULT 'pending'::text, start_date timestamp with time zone, end_date timestamp with time zone, first_post_id uuid, name text NOT NULL, creator_id uuid NOT NULL, created_at timestamp with time zone NOT NULL DEFAULT now(), id uuid NOT NULL DEFAULT gen_random_uuid(), description text NOT NULL, highlight_type text NOT NULL);
