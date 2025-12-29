-- ============================================================================
-- TABELA: communities
-- ============================================================================

CREATE TABLE public.communities (emoji text DEFAULT '🏢'::text, description text, slug text NOT NULL, name text NOT NULL, id uuid NOT NULL DEFAULT uuid_generate_v4(), is_active boolean DEFAULT true, updated_at timestamp without time zone DEFAULT now(), created_at timestamp without time zone DEFAULT now(), owner_id uuid NOT NULL, logo_url text);
