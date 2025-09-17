-- ============================================================================
-- POINTS_HISTORY TABLE - Histórico de Pontuação
-- ============================================================================
-- Tabela que registra todo o histórico de pontos ganhos pelos usuários
-- Sistema de auditoria completa da gamificação
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.points_history (
    -- Identificador único do registro
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Usuário que ganhou/perdeu pontos (obrigatório)
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Tipo da ação que gerou os pontos (obrigatório)
    action_type VARCHAR(50) NOT NULL,
    
    -- Quantidade de pontos ganhos/perdidos (obrigatório)
    points_earned INTEGER NOT NULL,
    
    -- Referência ao objeto que gerou os pontos (opcional)
    reference_id UUID,
    
    -- Tipo do objeto referenciado (opcional)
    reference_type VARCHAR(50),
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- ID do post relacionado (para contexto)
    post_id UUID,
    
    -- Tipo de reação (para reações específicas)
    reaction_type TEXT,
    
    -- ID do usuário que causou a reação (para contexto)
    reaction_user_id UUID
);

-- ============================================================================
-- ÍNDICES DA TABELA POINTS_HISTORY
-- ============================================================================

-- Índice principal para busca por usuário (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_points_history_user_id 
ON public.points_history (user_id);

-- Índice para busca por tipo de ação
CREATE INDEX IF NOT EXISTS idx_points_history_action_type 
ON public.points_history (action_type);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_points_history_created_at 
ON public.points_history (created_at DESC);

-- Índice composto para busca eficiente por usuário e data
CREATE INDEX IF NOT EXISTS idx_points_history_user_created 
ON public.points_history (user_id, created_at DESC);

-- Índice composto para busca por usuário e tipo de ação
CREATE INDEX IF NOT EXISTS idx_points_history_user_action 
ON public.points_history (user_id, action_type);

-- Índice para busca por referência
CREATE INDEX IF NOT EXISTS idx_points_history_reference 
ON public.points_history (reference_type, reference_id);

-- Índice para busca por post relacionado
CREATE INDEX IF NOT EXISTS idx_points_history_post_id 
ON public.points_history (post_id);

-- Índice para busca por usuário de reação
CREATE INDEX IF NOT EXISTS idx_points_history_reaction_user 
ON public.points_history (reaction_user_id);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.points_history IS 
'Tabela que registra todo o histórico de pontos ganhos pelos usuários.
Sistema de auditoria completa da gamificação do HoloSpot.';

COMMENT ON COLUMN public.points_history.id IS 'Identificador único do registro de pontos';
COMMENT ON COLUMN public.points_history.user_id IS 'Usuário que ganhou/perdeu os pontos';
COMMENT ON COLUMN public.points_history.action_type IS 'Tipo da ação que gerou os pontos';
COMMENT ON COLUMN public.points_history.points_earned IS 'Quantidade de pontos ganhos (positivo) ou perdidos (negativo)';
COMMENT ON COLUMN public.points_history.reference_id IS 'ID do objeto que gerou os pontos (post, comment, reaction, etc.)';
COMMENT ON COLUMN public.points_history.reference_type IS 'Tipo do objeto referenciado (post, comment, reaction, etc.)';
COMMENT ON COLUMN public.points_history.created_at IS 'Timestamp de quando os pontos foram registrados';
COMMENT ON COLUMN public.points_history.post_id IS 'ID do post relacionado (para contexto adicional)';
COMMENT ON COLUMN public.points_history.reaction_type IS 'Tipo específico de reação (touched, inspired, grateful)';
COMMENT ON COLUMN public.points_history.reaction_user_id IS 'ID do usuário que causou a reação (para contexto)';

-- ============================================================================
-- NOTAS SOBRE A TABELA POINTS_HISTORY
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 10 campos para auditoria completa
-- - UUID como chave primária com uuid_generate_v4()
-- - Foreign key obrigatória para profiles
-- - Campos obrigatórios: user_id, action_type, points_earned
-- - Campos contextuais opcionais para rastreabilidade
-- 
-- Relacionamentos:
-- - points_history.user_id → profiles.id (CASCADE DELETE)
-- - Relacionamentos implícitos via reference_id e post_id
-- 
-- Tipos de Ação Comuns:
-- - post_created: Criação de posts (+10 pontos)
-- - mentioned_in_post: Menção em posts (+5 pontos)
-- - comment_created: Criação de comentários (+5 pontos)
-- - comment_received: Recebimento de comentários (+3 pontos)
-- - reaction_given: Reações dadas (+3 pontos)
-- - reaction_received: Reações recebidas (+2 pontos)
-- - feedback_given: Feedbacks dados (+8 pontos)
-- - feedback_received: Feedbacks recebidos (+5 pontos)
-- - streak_bonus_*: Bônus por streaks (variável)
-- 
-- Tipos de Referência:
-- - post: Referência a posts
-- - comment: Referência a comentários
-- - reaction: Referência a reações
-- - feedback: Referência a feedbacks
-- - badge: Referência a badges
-- - streak: Referência a streaks
-- 
-- Sistema de Auditoria:
-- - Registro completo de todas as transações de pontos
-- - Rastreabilidade total das ações
-- - Contexto adicional com post_id e reaction_user_id
-- - Timestamps precisos para análise temporal
-- 
-- Funcionalidades:
-- - Histórico completo de pontuação
-- - Auditoria de gamificação
-- - Análise de engajamento
-- - Debugging de pontos
-- - Relatórios de atividade
-- 
-- Consultas Comuns:
-- - Total de pontos por usuário
-- - Histórico de pontos por período
-- - Pontos por tipo de ação
-- - Análise de engajamento
-- - Debugging de pontuação
-- 
-- Performance:
-- - Índices otimizados para consultas frequentes
-- - Busca eficiente por usuário e período
-- - Agregações rápidas por tipo de ação
-- - Contexto adicional sem impacto
-- 
-- Integridade:
-- - Foreign key garante usuários válidos
-- - Campos obrigatórios garantem dados mínimos
-- - Deleção em cascata mantém consistência
-- - Auditoria completa preservada
-- 
-- Manutenção:
-- - Tabela de crescimento contínuo
-- - Arquivamento periódico de dados antigos
-- - Monitoramento de performance
-- - Backup regular para preservar histórico
-- 
-- ============================================================================

