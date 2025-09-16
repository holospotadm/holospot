-- ============================================================================
-- NOTIFICATIONS TABLE - Sistema de Notificações
-- ============================================================================
-- Tabela que armazena todas as notificações do sistema
-- Sistema avançado com agrupamento e controle anti-spam
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
    group_data JSONB
);

-- ============================================================================
-- ÍNDICES DA TABELA NOTIFICATIONS
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

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.notifications IS 
'Tabela que armazena todas as notificações do sistema.
Sistema avançado com agrupamento e controle anti-spam.';

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

-- ============================================================================
-- NOTAS SOBRE A TABELA NOTIFICATIONS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 10 campos com funcionalidades avançadas
-- - UUID como chave primária com gen_random_uuid()
-- - Foreign keys para profiles (user_id obrigatório, from_user_id opcional)
-- - Campos obrigatórios: user_id, type, message
-- - Sistema de agrupamento: group_key, group_count, group_data
-- 
-- Relacionamentos:
-- - notifications.user_id → profiles.id (CASCADE DELETE)
-- - notifications.from_user_id → profiles.id (CASCADE DELETE)
-- 
-- Tipos de Notificação:
-- - comment: Comentários em posts
-- - reaction: Reações em posts
-- - follow: Novos seguidores
-- - mention: Menções em holofotes
-- - feedback: Feedbacks recebidos
-- - badge_earned: Badges conquistados
-- - streak: Milestones de streak
-- 
-- Sistema de Agrupamento:
-- - group_key: Chave para agrupar notificações similares
-- - group_count: Contador de quantas notificações foram agrupadas
-- - group_data: Dados JSON com informações adicionais
-- 
-- Sistema Anti-Spam:
-- - Janelas de tempo por tipo de notificação
-- - Agrupamento automático de notificações similares
-- - Prevenção de duplicatas
-- - Controle de frequência
-- 
-- Funcionalidades Avançadas:
-- - Notificações agrupadas ("João e mais 3 pessoas reagiram")
-- - Dados JSON para informações extras
-- - Sistema de leitura/não lida
-- - Ordenação cronológica
-- 
-- Consultas Comuns:
-- - Listar notificações não lidas de um usuário
-- - Marcar notificações como lidas
-- - Buscar notificações por tipo
-- - Contar notificações não lidas
-- - Listar notificações recentes
-- 
-- Performance:
-- - Índices otimizados para consultas frequentes
-- - Busca eficiente por usuário e status
-- - Ordenação rápida por data
-- - Agrupamento eficiente
-- 
-- Integridade:
-- - Foreign keys garantem usuários válidos
-- - Deleção em cascata mantém consistência
-- - Campos obrigatórios garantem dados mínimos
-- - JSONB para flexibilidade de dados
-- 
-- Manutenção:
-- - Limpeza periódica de notificações antigas
-- - Monitoramento de crescimento da tabela
-- - Otimização de índices conforme uso
-- - Backup regular para preservar histórico
-- 
-- ============================================================================

