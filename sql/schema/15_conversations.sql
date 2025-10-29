-- ============================================================================
-- CONVERSATIONS TABLE - Sistema de Conversas/Chat
-- ============================================================================
-- Tabela que armazena conversas entre dois usuários
-- Sistema de mensagens diretas do HoloSpot
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    -- ID único da conversa
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Primeiro usuário (menor UUID)
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Segundo usuário (maior UUID)
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Data de criação da conversa
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Data da última atualização (última mensagem)
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Garantir que user1_id < user2_id (ordem consistente)
    CONSTRAINT conversations_user_order CHECK (user1_id < user2_id),
    
    -- Garantir que não existam conversas duplicadas
    CONSTRAINT conversations_unique_pair UNIQUE (user1_id, user2_id)
);

-- ============================================================================
-- ÍNDICES DA TABELA CONVERSATIONS
-- ============================================================================

-- Índice para busca por primeiro usuário
CREATE INDEX IF NOT EXISTS idx_conversations_user1 
ON public.conversations(user1_id);

-- Índice para busca por segundo usuário
CREATE INDEX IF NOT EXISTS idx_conversations_user2 
ON public.conversations(user2_id);

-- Índice para ordenação por última atualização
CREATE INDEX IF NOT EXISTS idx_conversations_updated 
ON public.conversations(updated_at DESC);

-- ============================================================================
-- RLS (ROW LEVEL SECURITY) DA TABELA CONVERSATIONS
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver conversas das quais participam
CREATE POLICY "Users can view their own conversations"
    ON public.conversations
    FOR SELECT
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Política: Usuários podem criar novas conversas
CREATE POLICY "Users can create conversations"
    ON public.conversations
    FOR INSERT
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.conversations IS 
'Tabela que armazena conversas entre dois usuários.
Sistema de mensagens diretas do HoloSpot.';

COMMENT ON COLUMN public.conversations.id IS 'ID único da conversa';
COMMENT ON COLUMN public.conversations.user1_id IS 'ID do primeiro usuário (menor UUID)';
COMMENT ON COLUMN public.conversations.user2_id IS 'ID do segundo usuário (maior UUID)';
COMMENT ON COLUMN public.conversations.created_at IS 'Data de criação da conversa';
COMMENT ON COLUMN public.conversations.updated_at IS 'Data da última atualização (última mensagem)';

-- ============================================================================
-- NOTAS SOBRE A TABELA CONVERSATIONS
-- ============================================================================
-- 
-- Estrutura:
-- - 5 campos para controle completo de conversas
-- - id como chave primária UUID
-- - user1_id e user2_id para os participantes
-- - Ordem consistente garantida (user1_id < user2_id)
-- - Constraint UNIQUE para evitar duplicatas
-- 
-- Relacionamentos:
-- - conversations.user1_id → auth.users.id (CASCADE DELETE)
-- - conversations.user2_id → auth.users.id (CASCADE DELETE)
-- 
-- Sistema de Ordem:
-- - user1_id sempre menor que user2_id
-- - Facilita busca e evita duplicatas
-- - Função get_or_create_conversation garante ordem
-- 
-- RLS (Row Level Security):
-- - Usuários só veem suas próprias conversas
-- - Verificação em ambos user1_id e user2_id
-- - Segurança garantida no nível do banco
-- 
-- Triggers Ativos:
-- - update_conversation_timestamp (em messages)
-- - Atualiza updated_at quando nova mensagem
-- 
-- Funcionalidades:
-- - Chat entre dois usuários
-- - Histórico de conversas
-- - Ordenação por atividade
-- - Busca eficiente
-- 
-- Consultas Comuns:
-- - Listar conversas de um usuário
-- - Buscar conversa entre dois usuários
-- - Ordenar por última atividade
-- - Contar conversas ativas
-- 
-- Performance:
-- - Índices em user1_id e user2_id
-- - Índice em updated_at para ordenação
-- - Constraint UNIQUE para evitar duplicatas
-- 
-- Integridade:
-- - Foreign keys garantem usuários válidos
-- - Deleção em cascata mantém consistência
-- - Constraint CHECK garante ordem
-- - UNIQUE garante não duplicatas
-- 
-- ============================================================================

