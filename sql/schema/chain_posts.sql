-- ============================================================================
-- TABELA: chain_posts
-- ============================================================================
-- DESCRIÇÃO:
-- Associa posts individuais a uma corrente e rastreia a origem de cada
-- participação, permitindo a reconstrução da árvore de engajamento.
--
-- RASTREAMENTO:
-- - parent_post_author_id = NULL → Post do criador (nível 0)
-- - parent_post_author_id != NULL → Post de participante (nível 1+)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chain_posts (
    -- Identificador único da associação
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- ID da corrente
    chain_id UUID NOT NULL REFERENCES public.chains(id) ON DELETE CASCADE,
    
    -- ID do post que faz parte da corrente
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    
    -- ID do autor do post
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- ID do autor do post que originou a participação
    -- NULL para o post inicial do criador
    parent_post_author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Garantir que um post pertence a apenas uma corrente
    UNIQUE(post_id)
);

-- ============================================================================
-- ÍNDICES
-- ============================================================================

-- Índice para consultas por corrente
CREATE INDEX IF NOT EXISTS idx_chain_posts_chain_id ON public.chain_posts(chain_id);

-- Índice para consultas por post
CREATE INDEX IF NOT EXISTS idx_chain_posts_post_id ON public.chain_posts(post_id);

-- Índice para consultas por autor
CREATE INDEX IF NOT EXISTS idx_chain_posts_author_id ON public.chain_posts(author_id);

-- Índice para rastreamento da cadeia de participação
CREATE INDEX IF NOT EXISTS idx_chain_posts_parent_author ON public.chain_posts(parent_post_author_id);

-- Índice para consultas por data de criação
CREATE INDEX IF NOT EXISTS idx_chain_posts_created_at ON public.chain_posts(created_at DESC);

-- Índice composto para consultas de profundidade
CREATE INDEX IF NOT EXISTS idx_chain_posts_chain_author ON public.chain_posts(chain_id, author_id);

-- ============================================================================
-- COMENTÁRIOS
-- ============================================================================

COMMENT ON TABLE public.chain_posts IS 'Associa posts a correntes e rastreia a cadeia de participação';
COMMENT ON COLUMN public.chain_posts.id IS 'Identificador único da associação';
COMMENT ON COLUMN public.chain_posts.chain_id IS 'ID da corrente à qual o post pertence';
COMMENT ON COLUMN public.chain_posts.post_id IS 'ID do post que integra a corrente';
COMMENT ON COLUMN public.chain_posts.author_id IS 'ID do autor do post';
COMMENT ON COLUMN public.chain_posts.parent_post_author_id IS 'ID do autor do post que originou a participação (NULL para criador)';
COMMENT ON COLUMN public.chain_posts.created_at IS 'Timestamp de criação do post na corrente';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.chain_posts ENABLE ROW LEVEL SECURITY;

-- Política de LEITURA: Todos podem visualizar posts de correntes
CREATE POLICY "Posts de correntes são públicos"
    ON public.chain_posts
    FOR SELECT
    USING (true);

-- Política de INSERÇÃO: Usuários autenticados podem adicionar posts
-- Restrição: Apenas em correntes ativas
CREATE POLICY "Usuários autenticados podem adicionar posts a correntes ativas"
    ON public.chain_posts
    FOR INSERT
    WITH CHECK (
        auth.uid() = author_id
        AND EXISTS (
            SELECT 1 FROM public.chains
            WHERE chains.id = chain_posts.chain_id
            AND chains.status = 'active'
        )
    );

-- Política de DELEÇÃO: Apenas autor pode deletar seu post da corrente
CREATE POLICY "Autor pode deletar seu post da corrente"
    ON public.chain_posts
    FOR DELETE
    USING (auth.uid() = author_id);

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================
