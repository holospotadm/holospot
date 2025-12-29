-- ============================================================================
-- TABELA: badges
-- ============================================================================

CREATE TABLE public.badges (name character varying(100) NOT NULL, description text NOT NULL, icon character varying(10) NOT NULL, category character varying(50) NOT NULL, updated_at timestamp with time zone DEFAULT now(), id uuid NOT NULL DEFAULT uuid_generate_v4(), condition_type character varying(50) NOT NULL, condition_value integer NOT NULL, rarity character varying(20) DEFAULT 'common'::character varying, is_active boolean DEFAULT true, created_at timestamp with time zone DEFAULT now(), points_required integer DEFAULT 0);
