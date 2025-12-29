-- ============================================================================
-- TABELA: invites
-- ============================================================================

CREATE TABLE public.invites (used_at timestamp with time zone, created_by uuid, created_at timestamp with time zone DEFAULT now(), id uuid NOT NULL DEFAULT gen_random_uuid(), code character varying(11) NOT NULL, used_by uuid);
