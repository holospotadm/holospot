-- ============================================================================
-- TABELA: profiles
-- ============================================================================

CREATE TABLE public.profiles (updated_at timestamp with time zone DEFAULT now(), community_owner boolean DEFAULT false, default_feed text DEFAULT 'recommended'::text, timezone text DEFAULT 'America/Sao_Paulo'::text, username character varying(50), created_at timestamp with time zone DEFAULT now(), avatar_url text, id uuid NOT NULL, email text, name text, invite_code_used character varying(11), invited_by uuid, birth_date date);
