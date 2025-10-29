-- ============================================================================
-- HOLOSPOT - SETUP DE CHAT/MENSAGENS DIRETAS
-- ============================================================================
-- Execute este arquivo no SQL Editor do Supabase para criar:
-- - Tabelas: conversations, messages
-- - Função: get_or_create_conversation
-- - Trigger: update_conversation_timestamp
-- - RLS Policies para segurança
-- ============================================================================

-- ============================================================================
-- 1. TABELA: CONVERSATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT conversations_user_order CHECK (user1_id < user2_id),
    CONSTRAINT conversations_unique_pair UNIQUE (user1_id, user2_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_conversations_user1 ON public.conversations(user1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user2 ON public.conversations(user2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated ON public.conversations(updated_at DESC);

-- RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own conversations" ON public.conversations;
CREATE POLICY "Users can view their own conversations"
    ON public.conversations
    FOR SELECT
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations"
    ON public.conversations
    FOR INSERT
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Comentários
COMMENT ON TABLE public.conversations IS 'Conversas entre dois usuários';
COMMENT ON COLUMN public.conversations.user1_id IS 'ID do primeiro usuário (menor UUID)';
COMMENT ON COLUMN public.conversations.user2_id IS 'ID do segundo usuário (maior UUID)';
COMMENT ON COLUMN public.conversations.updated_at IS 'Última atualização (última mensagem)';

-- ============================================================================
-- 2. TABELA: MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT messages_content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON public.messages(conversation_id, is_read) WHERE is_read = FALSE;

-- RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view messages from their conversations" ON public.messages;
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

DROP POLICY IF EXISTS "Users can send messages in their conversations" ON public.messages;
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

DROP POLICY IF EXISTS "Users can mark messages as read" ON public.messages;
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
COMMENT ON COLUMN public.messages.conversation_id IS 'ID da conversa';
COMMENT ON COLUMN public.messages.sender_id IS 'ID do remetente';
COMMENT ON COLUMN public.messages.content IS 'Conteúdo da mensagem';
COMMENT ON COLUMN public.messages.is_read IS 'Indica se foi lida';

-- ============================================================================
-- 3. FUNÇÃO: get_or_create_conversation
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_conversation_id UUID;
    v_min_user_id UUID;
    v_max_user_id UUID;
BEGIN
    -- Garantir ordem consistente (user1 < user2)
    IF p_user1_id < p_user2_id THEN
        v_min_user_id := p_user1_id;
        v_max_user_id := p_user2_id;
    ELSE
        v_min_user_id := p_user2_id;
        v_max_user_id := p_user1_id;
    END IF;
    
    -- Buscar conversa existente
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE user1_id = v_min_user_id
    AND user2_id = v_max_user_id;
    
    -- Se não existir, criar nova conversa
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (user1_id, user2_id)
        VALUES (v_min_user_id, v_max_user_id)
        RETURNING id INTO v_conversation_id;
    END IF;
    
    RETURN v_conversation_id;
END;
$function$;

COMMENT ON FUNCTION public.get_or_create_conversation IS 
'Busca ou cria uma conversa entre dois usuários';

-- ============================================================================
-- 4. TRIGGER: update_conversation_timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.update_conversation_timestamp IS 
'Atualiza timestamp da conversa quando nova mensagem é enviada';

DROP TRIGGER IF EXISTS trigger_update_conversation_timestamp ON public.messages;

CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_timestamp();

-- ============================================================================
-- FIM DO SETUP
-- ============================================================================

-- Verificar se tudo foi criado corretamente
SELECT 
    'conversations' as table_name, 
    COUNT(*) as row_count 
FROM public.conversations
UNION ALL
SELECT 
    'messages' as table_name, 
    COUNT(*) as row_count 
FROM public.messages;

-- ============================================================================
-- SUCESSO! 🎉
-- ============================================================================
-- Tabelas, função, trigger e policies criados com sucesso!
-- Agora você pode usar o chat no HoloSpot!
-- ============================================================================

