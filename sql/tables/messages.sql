-- ============================================================================
-- TABELA: messages
-- Descrição: Armazena mensagens dentro de conversas
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Validações
    CONSTRAINT messages_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(conversation_id, is_read) WHERE is_read = FALSE;

-- RLS (Row Level Security)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver mensagens das conversas das quais participam
CREATE POLICY "Users can view messages from their conversations"
    ON public.messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
        )
    );

-- Política: Usuários podem enviar mensagens nas conversas das quais participam
CREATE POLICY "Users can send messages in their conversations"
    ON public.messages
    FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
        )
    );

-- Política: Usuários podem marcar mensagens como lidas
CREATE POLICY "Users can mark messages as read"
    ON public.messages
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
        )
    );

-- Comentários
COMMENT ON TABLE public.messages IS 'Mensagens dentro de conversas';
COMMENT ON COLUMN public.messages.conversation_id IS 'ID da conversa à qual a mensagem pertence';
COMMENT ON COLUMN public.messages.sender_id IS 'ID do usuário que enviou a mensagem';
COMMENT ON COLUMN public.messages.content IS 'Conteúdo da mensagem';
COMMENT ON COLUMN public.messages.is_read IS 'Indica se a mensagem foi lida pelo destinatário';

