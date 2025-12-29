-- ============================================================================
-- TABELA: user_badges
-- ============================================================================

CREATE TABLE public.user_badges (earned_at timestamp with time zone DEFAULT now(), is_featured boolean DEFAULT false, id uuid NOT NULL DEFAULT uuid_generate_v4(), progress integer DEFAULT 0, badge_id uuid NOT NULL, user_id uuid NOT NULL);
