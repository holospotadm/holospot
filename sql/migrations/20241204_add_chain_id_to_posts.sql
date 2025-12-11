-- ============================================================================
-- MIGRATION: Adicionar coluna chain_id à tabela posts
-- ============================================================================
-- DATA: 04 de Dezembro de 2025
-- DESCRIÇÃO: Adiciona coluna para vincular posts diretamente às correntes
-- ============================================================================

-- Adicionar coluna chain_id (opcional, NULL se não for post de corrente)
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS chain_id UUID REFERENCES public.chains(id) ON DELETE SET NULL;

-- Criar índice para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_posts_chain_id ON public.posts(chain_id);

-- Adicionar comentário
COMMENT ON COLUMN public.posts.chain_id IS 'ID da corrente à qual o post pertence (NULL se não for post de corrente)';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'posts'
        AND column_name = 'chain_id'
    ) THEN
        RAISE NOTICE '✅ Coluna chain_id adicionada com sucesso à tabela posts';
    ELSE
        RAISE EXCEPTION '❌ Erro: Coluna chain_id não foi adicionada';
    END IF;
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
