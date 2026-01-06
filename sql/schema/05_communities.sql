-- ============================================================================
-- TABELA: communities
-- ============================================================================

CREATE TABLE public.communities (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    emoji text DEFAULT '🏢'::text,
    logo_url text,
    owner_id uuid NOT NULL,
    is_active boolean DEFAULT true,
    is_age_restricted boolean DEFAULT false,
    min_age_to_post integer DEFAULT NULL,
    allow_multiple_feedbacks boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

COMMENT ON COLUMN public.communities.is_age_restricted IS 'Se true, a comunidade tem restrição de idade para postagem';
COMMENT ON COLUMN public.communities.min_age_to_post IS 'Idade mínima para postar na comunidade (se is_age_restricted = true)';
COMMENT ON COLUMN public.communities.allow_multiple_feedbacks IS 'Se true, permite múltiplos feedbacks de diferentes usuários em um post';
