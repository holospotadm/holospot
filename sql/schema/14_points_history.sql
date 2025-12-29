-- ============================================================================
-- TABELA: points_history
-- ============================================================================

CREATE TABLE public.points_history (reaction_type text, reaction_user_id uuid, id uuid NOT NULL DEFAULT uuid_generate_v4(), user_id uuid NOT NULL, action_type character varying(50) NOT NULL, points_earned integer NOT NULL, reference_id uuid, reference_type character varying(50), created_at timestamp with time zone DEFAULT now(), post_id uuid);
