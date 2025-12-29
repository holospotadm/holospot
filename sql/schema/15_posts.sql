-- ============================================================================
-- TABELA: posts
-- ============================================================================

CREATE TABLE public.posts (id uuid NOT NULL DEFAULT gen_random_uuid(), photo_url text, created_at timestamp with time zone DEFAULT now(), person_name text, updated_at timestamp with time zone DEFAULT now(), highlight_type text, story text, chain_id uuid, community_id uuid, mentioned_user_id uuid, type text DEFAULT 'gratidão'::text, content text NOT NULL, celebrated_person_name text NOT NULL, user_id uuid);
