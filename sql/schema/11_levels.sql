-- ============================================================================
-- TABELA: levels
-- ============================================================================

CREATE TABLE public.levels (name character varying(50) NOT NULL, min_points integer, benefits text, color character varying(7) NOT NULL, icon character varying(10) NOT NULL, points_required integer NOT NULL, id integer NOT NULL, max_points integer);
