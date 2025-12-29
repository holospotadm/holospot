-- ============================================================================
-- TABELA: user_points
-- ============================================================================

CREATE TABLE public.user_points (updated_at timestamp with time zone DEFAULT now(), created_at timestamp with time zone DEFAULT now(), level_id integer DEFAULT 1, total_points integer DEFAULT 0, user_id uuid NOT NULL, id uuid NOT NULL DEFAULT uuid_generate_v4(), points_to_next_level integer DEFAULT 50);
