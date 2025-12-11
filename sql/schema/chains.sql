-- ============================================================================
-- TABELA: chains
-- ============================================================================
-- DESCRIÇÃO:
-- Armazena as informações principais de cada corrente criada.
-- Uma corrente é uma sequência de posts temáticos que incentiva engajamento.
--
-- CICLO DE VIDA:
-- 1. 'pending' - Corrente criada, aguardando primeiro post
-- 2. 'active' - Corrente ativa, aceitando participações
-- 3. 'closed' - Corrente encerrada, histórico visível, sem novas participações
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chains (
    -- Identificador único da corrente
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Criador da corrente
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Nome da corrente (exibido nos posts e modais)
    name TEXT NOT NULL CHECK (char_length(name) >= 3 AND char_length(name) <= 50),
    
    -- Descrição detalhada (exibida em tooltips)
    description TEXT NOT NULL CHECK (char_length(description) >= 10 AND char_length(description) <= 200),
    
    -- Tipo de destaque fixo associado à corrente
    highlight_type TEXT NOT NULL,
    
    -- Status da corrente
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'closed')),
    
    -- Data de início (quando o primeiro post é criado)
    start_date TIMESTAMPTZ,
    
    -- Data de fechamento (quando o criador encerra a corrente)
    end_date TIMESTAMPTZ,
    
    -- ID do primeiro post da corrente
    first_post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL
);

-- ============================================================================
-- ÍNDICES
-- ============================================================================

-- Índice para consultas por criador
CREATE INDEX IF NOT EXISTS idx_chains_creator_id ON public.chains(creator_id);

-- Índice para consultas por status
CREATE INDEX IF NOT EXISTS idx_chains_status ON public.chains(status);

-- Índice para consultas por data de criação
CREATE INDEX IF NOT EXISTS idx_chains_created_at ON public.chains(created_at DESC);

-- ============================================================================
-- COMENTÁRIOS
-- ============================================================================

COMMENT ON TABLE public.chains IS 'Armazena informações de correntes (sequências de posts temáticos)';
COMMENT ON COLUMN public.chains.id IS 'Identificador único da corrente';
COMMENT ON COLUMN public.chains.creator_id IS 'ID do usuário que criou a corrente';
COMMENT ON COLUMN public.chains.name IS 'Nome da corrente (3-50 caracteres)';
COMMENT ON COLUMN public.chains.description IS 'Descrição da corrente (10-200 caracteres)';
COMMENT ON COLUMN public.chains.highlight_type IS 'Tipo de destaque fixo (Apoio, Inspiração, etc.)';
COMMENT ON COLUMN public.chains.status IS 'Status: pending, active ou closed';
COMMENT ON COLUMN public.chains.start_date IS 'Data de início (quando primeiro post é criado)';
COMMENT ON COLUMN public.chains.end_date IS 'Data de fechamento (quando criador encerra)';
COMMENT ON COLUMN public.chains.first_post_id IS 'ID do primeiro post que iniciou a corrente';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.chains ENABLE ROW LEVEL SECURITY;

-- Política de LEITURA: Todos podem visualizar correntes ativas ou fechadas
CREATE POLICY "Correntes ativas e fechadas são públicas"
    ON public.chains
    FOR SELECT
    USING (status IN ('active', 'closed'));

-- Política de LEITURA: Criador pode visualizar suas correntes pendentes
CREATE POLICY "Criador pode ver suas correntes pendentes"
    ON public.chains
    FOR SELECT
    USING (auth.uid() = creator_id);

-- Política de INSERÇÃO: Usuários autenticados podem criar correntes
CREATE POLICY "Usuários autenticados podem criar correntes"
    ON public.chains
    FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Política de ATUALIZAÇÃO: Apenas criador pode atualizar sua corrente
CREATE POLICY "Criador pode atualizar sua corrente"
    ON public.chains
    FOR UPDATE
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- Política de DELEÇÃO: Apenas criador pode deletar corrente pendente
CREATE POLICY "Criador pode deletar corrente pendente"
    ON public.chains
    FOR DELETE
    USING (auth.uid() = creator_id AND status = 'pending');

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================
