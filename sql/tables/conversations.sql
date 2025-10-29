-- ============================================================================
-- TABELA: conversations
-- Descrição: Armazena conversas entre dois usuários
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Garantir que user1_id < user2_id (ordem consistente)
    CONSTRAINT conversations_user_order CHECK (user1_id < user2_id),
    
    -- Garantir que não existam conversas duplicadas
    CONSTRAINT conversations_unique_pair UNIQUE (user1_id, user2_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON public.conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON public.conversations(user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);

-- RLS (Row Level Security)
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

-- Comentários
COMMENT ON TABLE public.conversations IS 'Conversas entre dois usuários';
COMMENT ON COLUMN public.conversations.user1_id IS 'ID do primeiro usuário (menor UUID)';
COMMENT ON COLUMN public.conversations.user2_id IS 'ID do segundo usuário (maior UUID)';
COMMENT ON COLUMN public.conversations.updated_at IS 'Última atualização (última mensagem)';

