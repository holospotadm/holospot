-- ============================================================================
-- NOTIFICATIONS TABLE - Sistema de Notificações (ATUALIZADA)
-- ============================================================================
-- Tabela que armazena todas as notificações do sistema
-- Sistema avançado com agrupamento e controle anti-spam
-- ATUALIZAÇÃO: Adicionado campo post_id para notificações clicáveis
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    -- Identificador único da notificação
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usuário que recebe a notificação (obrigatório)
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Usuário que originou a notificação (opcional)
    from_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Tipo da notificação (obrigatório)
    type TEXT NOT NULL,
    
    -- Mensagem da notificação (obrigatória)
    message TEXT NOT NULL,
    
    -- Se a notificação foi lida
    read BOOLEAN DEFAULT false,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Chave para agrupamento de notificações similares
    group_key TEXT,
    
    -- Contador de notificações agrupadas
    group_count INTEGER DEFAULT 1,
    
    -- Dados adicionais em formato JSON
    group_data JSONB,
    
    -- *** NOVO CAMPO *** ID do post relacionado (para notificações clicáveis)
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE
);

-- ============================================================================
-- ÍNDICES DA TABELA NOTIFICATIONS (ATUALIZADOS)
-- ============================================================================

-- Índice principal para busca por usuário (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id 
ON public.notifications (user_id);

-- Índice para busca por usuário remetente
CREATE INDEX IF NOT EXISTS idx_notifications_from_user_id 
ON public.notifications (from_user_id);

-- Índice para busca por tipo
CREATE INDEX IF NOT EXISTS idx_notifications_type 
ON public.notifications (type);

-- Índice para busca por status de leitura
CREATE INDEX IF NOT EXISTS idx_notifications_read 
ON public.notifications (read);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_notifications_created_at 
ON public.notifications (created_at DESC);

-- Índice composto para busca eficiente por usuário e status
CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
ON public.notifications (user_id, read);

-- Índice composto para busca por usuário e data
CREATE INDEX IF NOT EXISTS idx_notifications_user_created 
ON public.notifications (user_id, created_at DESC);

-- Índice para agrupamento de notificações
CREATE INDEX IF NOT EXISTS idx_notifications_group_key 
ON public.notifications (group_key);

-- Índice para busca por tipo e data (anti-spam)
CREATE INDEX IF NOT EXISTS idx_notifications_type_created 
ON public.notifications (type, created_at);

-- *** NOVO ÍNDICE *** Para busca por post relacionado
CREATE INDEX IF NOT EXISTS idx_notifications_post_id 
ON public.notifications (post_id);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO (ATUALIZADOS)
-- ============================================================================

COMMENT ON TABLE public.notifications IS 
'Tabela que armazena todas as notificações do sistema.
Sistema avançado com agrupamento e controle anti-spam.
ATUALIZAÇÃO: Inclui campo post_id para notificações clicáveis.';

COMMENT ON COLUMN public.notifications.id IS 'Identificador único da notificação (UUID)';
COMMENT ON COLUMN public.notifications.user_id IS 'Usuário que recebe a notificação';
COMMENT ON COLUMN public.notifications.from_user_id IS 'Usuário que originou a notificação (opcional)';
COMMENT ON COLUMN public.notifications.type IS 'Tipo da notificação (comment, reaction, follow, etc.)';
COMMENT ON COLUMN public.notifications.message IS 'Mensagem da notificação exibida ao usuário';
COMMENT ON COLUMN public.notifications.read IS 'Se a notificação foi lida pelo usuário';
COMMENT ON COLUMN public.notifications.created_at IS 'Timestamp de criação da notificação';
COMMENT ON COLUMN public.notifications.group_key IS 'Chave para agrupamento de notificações similares';
COMMENT ON COLUMN public.notifications.group_count IS 'Contador de notificações agrupadas';
COMMENT ON COLUMN public.notifications.group_data IS 'Dados adicionais em formato JSON para agrupamento';
COMMENT ON COLUMN public.notifications.post_id IS 'ID do post relacionado à notificação (para notificações clicáveis)';

-- ============================================================================
-- NOTAS SOBRE A ATUALIZAÇÃO
-- ============================================================================
-- 
-- CAMPO ADICIONADO:
-- - post_id: UUID que referencia posts(id) com CASCADE DELETE
-- - Permite notificações clicáveis que abrem posts específicos
-- - Usado para tipos: comment, reaction, mention, feedback
-- 
-- TIPOS QUE TERÃO post_id:
-- - comment: Comentários em posts → post_id do post comentado
-- - reaction: Reações em posts → post_id do post que recebeu reação
-- - mention: Menções em posts → post_id do post que menciona
-- - feedback: Feedbacks em posts → post_id do post que recebeu feedback
-- 
-- TIPOS QUE NÃO TERÃO post_id:
-- - follow: Novos seguidores → não relacionado a post específico
-- - badge_earned: Badges conquistados → não relacionado a post específico
-- - level_up: Level up → não relacionado a post específico
-- - milestone: Marcos de pontos → não relacionado a post específico
-- 
-- FUNCIONALIDADE FRONTEND:
-- - Notificações com post_id são renderizadas como clicáveis
-- - Onclick abre modal com o post específico
-- - Notificação é marcada como lida automaticamente
-- - Visual diferenciado (cursor pointer, hover effects)
-- 
-- ============================================================================
