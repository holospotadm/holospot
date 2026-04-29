-- ============================================================================
-- TABELA: profiles
-- Última atualização: 2026-04-28
-- Campos adicionados neste ciclo: bio (TEXT, nullable)
-- ============================================================================

CREATE TABLE public.profiles (
    id                      uuid NOT NULL,
    email                   text,
    name                    text,
    username                character varying(50),
    avatar_url              text,
    bio                     text,
    birth_date              date,
    timezone                text DEFAULT 'America/Sao_Paulo'::text,
    default_feed            text DEFAULT 'recommended'::text,
    community_owner         boolean DEFAULT false,
    invited_by              uuid,
    invite_code_used        character varying(11),
    has_completed_onboarding boolean DEFAULT false NOT NULL,
    created_at              timestamp with time zone DEFAULT now(),
    updated_at              timestamp with time zone DEFAULT now()
);
