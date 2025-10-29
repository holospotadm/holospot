-- ============================================
-- MIGRATION: Tornar slug obrigatório novamente
-- Descrição: Reverte mudança anterior e torna slug obrigatório e único
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- 1. Atualizar comunidades existentes sem slug (se houver)
UPDATE public.communities
SET slug = LOWER(REGEXP_REPLACE(name, '[^a-zA-Z0-9]+', '-', 'g'))
WHERE slug IS NULL;

-- 2. Tornar slug obrigatório e único
ALTER TABLE public.communities 
ALTER COLUMN slug SET NOT NULL;

ALTER TABLE public.communities
ADD CONSTRAINT communities_slug_unique UNIQUE (slug);

-- 3. Recriar índice
CREATE INDEX IF NOT EXISTS idx_communities_slug ON public.communities(slug);

-- 4. Atualizar comentário
COMMENT ON COLUMN public.communities.slug IS 
'URL slug da comunidade (obrigatório e único)';

-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Campo slug agora é obrigatório e único';
    RAISE NOTICE '📝 Comunidades existentes tiveram slug gerado automaticamente';
END $$;

