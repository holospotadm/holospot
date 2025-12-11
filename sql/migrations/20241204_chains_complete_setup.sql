-- ============================================================================
-- MIGRATION COMPLETA: Sistema de Correntes - Fase 1 (Banco de Dados)
-- ============================================================================
-- DATA: 04 de Dezembro de 2025
-- DESCRIÇÃO: Cria toda a estrutura de banco de dados para o sistema de correntes
-- EXECUTAR: No Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. TABELA: chains
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(name) >= 3 AND char_length(name) <= 50),
    description TEXT NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 200),
    highlight_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'closed')),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    first_post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_chains_creator_id ON public.chains(creator_id);
CREATE INDEX IF NOT EXISTS idx_chains_status ON public.chains(status);
CREATE INDEX IF NOT EXISTS idx_chains_created_at ON public.chains(created_at DESC);

-- Comentários
COMMENT ON TABLE public.chains IS 'Armazena informações de correntes (sequências de posts temáticos)';
COMMENT ON COLUMN public.chains.status IS 'Status: pending, active ou closed';

-- RLS
ALTER TABLE public.chains ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Correntes ativas e fechadas são públicas" ON public.chains;
CREATE POLICY "Correntes ativas e fechadas são públicas"
    ON public.chains FOR SELECT
    USING (status IN ('active', 'closed'));

DROP POLICY IF EXISTS "Criador pode ver suas correntes pendentes" ON public.chains;
CREATE POLICY "Criador pode ver suas correntes pendentes"
    ON public.chains FOR SELECT
    USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Usuários autenticados podem criar correntes" ON public.chains;
CREATE POLICY "Usuários autenticados podem criar correntes"
    ON public.chains FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Criador pode atualizar sua corrente" ON public.chains;
CREATE POLICY "Criador pode atualizar sua corrente"
    ON public.chains FOR UPDATE
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Criador pode deletar corrente pendente" ON public.chains;
CREATE POLICY "Criador pode deletar corrente pendente"
    ON public.chains FOR DELETE
    USING (auth.uid() = creator_id AND status = 'pending');

-- ============================================================================
-- 2. TABELA: chain_posts
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chain_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_id UUID NOT NULL REFERENCES public.chains(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    parent_post_author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_chain_posts_chain_id ON public.chain_posts(chain_id);
CREATE INDEX IF NOT EXISTS idx_chain_posts_post_id ON public.chain_posts(post_id);
CREATE INDEX IF NOT EXISTS idx_chain_posts_author_id ON public.chain_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_chain_posts_parent_author ON public.chain_posts(parent_post_author_id);
CREATE INDEX IF NOT EXISTS idx_chain_posts_created_at ON public.chain_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chain_posts_chain_author ON public.chain_posts(chain_id, author_id);

-- Comentários
COMMENT ON TABLE public.chain_posts IS 'Associa posts a correntes e rastreia a cadeia de participação';

-- RLS
ALTER TABLE public.chain_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Posts de correntes são públicos" ON public.chain_posts;
CREATE POLICY "Posts de correntes são públicos"
    ON public.chain_posts FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem adicionar posts a correntes ativas" ON public.chain_posts;
CREATE POLICY "Usuários autenticados podem adicionar posts a correntes ativas"
    ON public.chain_posts FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.chains
            WHERE chains.id = chain_posts.chain_id
            AND chains.status = 'active'
        )
    );

DROP POLICY IF EXISTS "Autor pode deletar seu post da corrente" ON public.chain_posts;
CREATE POLICY "Autor pode deletar seu post da corrente"
    ON public.chain_posts FOR DELETE
    USING (auth.uid() = author_id);

-- ============================================================================
-- 3. ALTERAÇÃO: Adicionar chain_id à tabela posts
-- ============================================================================

ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS chain_id UUID REFERENCES public.chains(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_posts_chain_id ON public.posts(chain_id);

COMMENT ON COLUMN public.posts.chain_id IS 'ID da corrente à qual o post pertence (NULL se não for post de corrente)';

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================

DO $$
DECLARE
    v_chains_exists BOOLEAN;
    v_chain_posts_exists BOOLEAN;
    v_posts_column_exists BOOLEAN;
BEGIN
    -- Verificar tabela chains
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'chains'
    ) INTO v_chains_exists;
    
    -- Verificar tabela chain_posts
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'chain_posts'
    ) INTO v_chain_posts_exists;
    
    -- Verificar coluna chain_id em posts
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'posts' AND column_name = 'chain_id'
    ) INTO v_posts_column_exists;
    
    -- Relatório
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ FASE 1: BANCO DE DADOS - VERIFICAÇÃO FINAL';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    
    IF v_chains_exists THEN
        RAISE NOTICE '✅ Tabela chains criada com sucesso';
    ELSE
        RAISE EXCEPTION '❌ Erro: Tabela chains não foi criada';
    END IF;
    
    IF v_chain_posts_exists THEN
        RAISE NOTICE '✅ Tabela chain_posts criada com sucesso';
    ELSE
        RAISE EXCEPTION '❌ Erro: Tabela chain_posts não foi criada';
    END IF;
    
    IF v_posts_column_exists THEN
        RAISE NOTICE '✅ Coluna chain_id adicionada à tabela posts';
    ELSE
        RAISE EXCEPTION '❌ Erro: Coluna chain_id não foi adicionada';
    END IF;
    
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '🎉 FASE 1 CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
