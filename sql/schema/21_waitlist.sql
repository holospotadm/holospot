-- ============================================================================
-- TABELA: waitlist
-- ============================================================================

CREATE TABLE public.waitlist (google_id uuid, email character varying(255) NOT NULL, id uuid NOT NULL DEFAULT gen_random_uuid(), invite_code character varying(11) DEFAULT NULL::character varying, invited_at timestamp with time zone, created_at timestamp with time zone DEFAULT now(), google_name character varying(255) DEFAULT NULL::character varying);
