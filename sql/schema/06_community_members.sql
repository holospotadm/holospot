-- ============================================================================
-- TABELA: community_members
-- ============================================================================

CREATE TABLE public.community_members (joined_at timestamp without time zone DEFAULT now(), role text DEFAULT 'member'::text, user_id uuid, community_id uuid, id uuid NOT NULL DEFAULT uuid_generate_v4(), is_active boolean DEFAULT true);
