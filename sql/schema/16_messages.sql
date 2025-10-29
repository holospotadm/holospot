-- ============================================================================
-- MESSAGES TABLE - Sistema de Mensagens
-- ============================================================================
-- Tabela que armazena mensagens dentro de conversas
-- Sistema de chat direto do HoloSpot
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.messages (
    -- ID único da mensagem
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- ID da conversa à qual a mensagem pertence
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    
    -- ID do usuário que enviou a mensagem
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Conteúdo da mensagem
    content TEXT NOT NULL,
    
    -- Indica se a mensagem foi lida pelo destinatário
    is_read BOOLEAN DEFAULT FALSE,
    
    -- Data de criação da mensagem
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Validação: conteúdo não pode ser vazio
    CONSTRAINT messages_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- ============================================================================
-- ÍNDICES DA TABELA MESSAGES
-- ============================================================================

-- Índice para busca por conversa e ordenação por data
CREATE INDEX IF NOT EXISTS idx_messages_conversation 
ON public.messages(conversation_id, created_at DESC);

-- Índice para busca por remetente
CREATE INDEX IF NOT EXISTS idx_messages_sender 
ON public.messages(sender_id);

-- Índice para busca por mensagens não lidas
CREATE INDEX IF NOT EXISTS idx_messages_unread 
ON public.messages(conversation_id, is_read) 
WHERE is_read = FALSE;

-- ============================================================================
-- RLS (ROW LEVEL SECURITY) DA TABELA MESSAGES
-- ============================================================================

-- Habilitar RLS
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

-- ============================================================================
-- TRIGGERS DA TABELA MESSAGES
-- ============================================================================

-- Trigger para atualizar timestamp da conversa quando nova mensagem é enviada
CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.messages IS 
'Tabela que armazena mensagens dentro de conversas.
Sistema de chat direto do HoloSpot.';

COMMENT ON COLUMN public.messages.id IS 'ID único da mensagem';
COMMENT ON COLUMN public.messages.conversation_id IS 'ID da conversa à qual a mensagem pertence';
COMMENT ON COLUMN public.messages.sender_id IS 'ID do usuário que enviou a mensagem';
COMMENT ON COLUMN public.messages.content IS 'Conteúdo da mensagem';
COMMENT ON COLUMN public.messages.is_read IS 'Indica se a mensagem foi lida pelo destinatário';
COMMENT ON COLUMN public.messages.created_at IS 'Data de criação da mensagem';

-- ============================================================================
-- NOTAS SOBRE A TABELA MESSAGES
-- ============================================================================
-- 
-- Estrutura:
-- - 6 campos para controle completo de mensagens
-- - id como chave primária UUID
-- - conversation_id para relacionar com conversa
-- - sender_id para identificar remetente
-- - content para texto da mensagem
-- - is_read para controle de leitura
-- - created_at para ordenação temporal
-- 
-- Relacionamentos:
-- - messages.conversation_id → conversations.id (CASCADE DELETE)
-- - messages.sender_id → auth.users.id (CASCADE DELETE)
-- 
-- Sistema de Leitura:
-- - is_read padrão FALSE
-- - Marcado TRUE quando destinatário abre conversa
-- - Usado para contador de não lidas
-- 
-- RLS (Row Level Security):
-- - Usuários só veem mensagens de suas conversas
-- - Verificação via EXISTS em conversations
-- - Usuários só podem enviar como sender_id próprio
-- - Segurança garantida no nível do banco
-- 
-- Triggers Ativos:
-- - trigger_update_conversation_timestamp
-- - Atualiza updated_at da conversa
-- - Mantém conversas ordenadas por atividade
-- 
-- Funcionalidades:
-- - Envio de mensagens
-- - Histórico de chat
-- - Controle de leitura
-- - Real-time com subscriptions
-- 
-- Validações:
-- - content não pode ser vazio (CHECK)
-- - sender_id deve ser usuário válido (FK)
-- - conversation_id deve existir (FK)
-- 
-- Consultas Comuns:
-- - Listar mensagens de uma conversa
-- - Contar mensagens não lidas
-- - Buscar última mensagem
-- - Marcar mensagens como lidas
-- 
-- Performance:
-- - Índice composto (conversation_id, created_at)
-- - Índice parcial para is_read = FALSE
-- - Índice em sender_id
-- - Otimizado para ordenação DESC
-- 
-- Integridade:
-- - Foreign keys garantem relacionamentos válidos
-- - Deleção em cascata mantém consistência
-- - Constraint CHECK garante conteúdo válido
-- - RLS garante segurança
-- 
-- Real-time:
-- - Supabase subscriptions em INSERT
-- - Atualização automática de UI
-- - Notificações instantâneas
-- 
-- ============================================================================

