-- ============================================================================
-- MIGRATION: Adicionar campo bio à tabela profiles
-- Data: 2026-04-06
-- Descrição: Campo bio (TEXT, nullable) para exibição no perfil do usuário
-- Status: EXECUTADO no banco (confirmado via information_schema em 2026-04-28)
-- ============================================================================

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS bio TEXT;

COMMENT ON COLUMN public.profiles.bio IS 'Texto de apresentação do usuário exibido no perfil';

-- Validação
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'bio'
    ) THEN
        RAISE NOTICE '✅ Campo bio existe em profiles';
    ELSE
        RAISE EXCEPTION '❌ Campo bio NÃO encontrado em profiles';
    END IF;
END $$;
