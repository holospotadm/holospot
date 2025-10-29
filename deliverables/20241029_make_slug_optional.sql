-- ============================================
-- MIGRATION: Tornar slug opcional
-- Descrição: Remove obrigatoriedade do campo slug
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Tornar coluna slug nullable (se ainda não for)
ALTER TABLE public.communities 
ALTER COLUMN slug DROP NOT NULL;

-- Adicionar comentário
COMMENT ON COLUMN public.communities.slug IS 
'URL slug da comunidade (opcional - não usado no MVP)';

-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Campo slug agora é opcional';
    RAISE NOTICE '📝 Comunidades podem ser criadas sem slug';
END $$;

