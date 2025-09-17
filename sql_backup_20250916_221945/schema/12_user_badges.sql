-- ============================================================================
-- USER_BADGES TABLE - Badges Conquistados pelos Usuários
-- ============================================================================
-- Tabela que registra quais badges cada usuário conquistou
-- Sistema de conquistas e gamificação
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_badges (
    -- Identificador único do registro
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Usuário que conquistou o badge (obrigatório)
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Badge conquistado (obrigatório)
    badge_id UUID NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
    
    -- Timestamp de quando o badge foi conquistado
    earned_at TIMESTAMPTZ DEFAULT now(),
    
    -- Progresso atual para o badge (0-100 ou valor específico)
    progress INTEGER DEFAULT 0,
    
    -- Se o badge está em destaque no perfil
    is_featured BOOLEAN DEFAULT false
);

-- ============================================================================
-- CONSTRAINTS DA TABELA USER_BADGES
-- ============================================================================

-- Constraint única para evitar badges duplicados para o mesmo usuário
ALTER TABLE public.user_badges 
ADD CONSTRAINT unique_user_badge 
UNIQUE (user_id, badge_id);

-- ============================================================================
-- ÍNDICES DA TABELA USER_BADGES
-- ============================================================================

-- Índice para busca por usuário (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id 
ON public.user_badges (user_id);

-- Índice para busca por badge
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id 
ON public.user_badges (badge_id);

-- Índice para ordenação por data de conquista
CREATE INDEX IF NOT EXISTS idx_user_badges_earned_at 
ON public.user_badges (earned_at DESC);

-- Índice para badges em destaque
CREATE INDEX IF NOT EXISTS idx_user_badges_featured 
ON public.user_badges (is_featured) WHERE is_featured = true;

-- Índice composto para busca eficiente por usuário e data
CREATE INDEX IF NOT EXISTS idx_user_badges_user_earned 
ON public.user_badges (user_id, earned_at DESC);

-- Índice para progresso (para badges em andamento)
CREATE INDEX IF NOT EXISTS idx_user_badges_progress 
ON public.user_badges (progress) WHERE progress > 0 AND progress < 100;

-- ============================================================================
-- TRIGGERS DA TABELA USER_BADGES
-- ============================================================================

-- Trigger para notificação quando badge é conquistado
CREATE TRIGGER badge_notification_only_trigger 
    AFTER INSERT ON public.user_badges 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_badge_notification_only();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.user_badges IS 
'Tabela que registra quais badges cada usuário conquistou.
Sistema de conquistas e gamificação do HoloSpot.';

COMMENT ON COLUMN public.user_badges.id IS 'Identificador único do registro de badge conquistado';
COMMENT ON COLUMN public.user_badges.user_id IS 'Usuário que conquistou o badge';
COMMENT ON COLUMN public.user_badges.badge_id IS 'Badge que foi conquistado';
COMMENT ON COLUMN public.user_badges.earned_at IS 'Timestamp de quando o badge foi conquistado';
COMMENT ON COLUMN public.user_badges.progress IS 'Progresso atual para o badge (0-100 ou valor específico)';
COMMENT ON COLUMN public.user_badges.is_featured IS 'Se o badge está em destaque no perfil do usuário';

-- ============================================================================
-- NOTAS SOBRE A TABELA USER_BADGES
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 6 campos para gerenciamento completo de badges
-- - UUID como chave primária com uuid_generate_v4()
-- - Foreign keys obrigatórias para profiles e badges
-- - Campos opcionais: earned_at, progress, is_featured
-- - Sistema de progresso e destaque
-- 
-- Relacionamentos:
-- - user_badges.user_id → profiles.id (CASCADE DELETE)
-- - user_badges.badge_id → badges.id (CASCADE DELETE)
-- 
-- Sistema de Progresso:
-- - progress: 0-100 para badges em andamento
-- - Permite tracking de progresso antes da conquista
-- - Útil para badges com critérios complexos
-- 
-- Sistema de Destaque:
-- - is_featured: Permite destacar badges no perfil
-- - Usuário pode escolher quais badges exibir
-- - Personalização do perfil público
-- 
-- Sistema de Notificações:
-- - Notifica usuário quando conquista badge
-- - Inclui informações de raridade
-- - Mensagens de parabéns personalizadas
-- 
-- Triggers Ativos (1 total):
-- 1. badge_notification_only_trigger - Notificação de conquista
-- 
-- Funcionalidades:
-- - Registro de conquistas
-- - Progresso de badges
-- - Badges em destaque
-- - Histórico de conquistas
-- - Gamificação completa
-- 
-- Consultas Comuns:
-- - Listar badges de um usuário
-- - Badges conquistados recentemente
-- - Badges em destaque
-- - Progresso de badges específicos
-- - Estatísticas de conquistas
-- 
-- Validações:
-- - Um badge por usuário (constraint única)
-- - Referências válidas (FK)
-- - Progresso entre 0-100 (lógica)
-- - Deleção em cascata
-- 
-- Performance:
-- - Índices otimizados para consultas frequentes
-- - Busca eficiente por usuário
-- - Filtros para badges em destaque
-- - Ordenação por data de conquista
-- 
-- Integridade:
-- - Foreign keys garantem referências válidas
-- - Constraint única previne duplicatas
-- - Deleção em cascata mantém consistência
-- - Triggers garantem notificações
-- 
-- Gamificação:
-- - Motivação por conquistas
-- - Progresso visível
-- - Personalização de perfil
-- - Sistema de recompensas
-- 
-- Análise e Métricas:
-- - Badges mais conquistados
-- - Taxa de conquista por badge
-- - Progresso médio dos usuários
-- - Engajamento por raridade
-- 
-- Manutenção:
-- - Tabela de crescimento moderado
-- - Limpeza de progresso órfão
-- - Monitoramento de conquistas
-- - Backup de histórico
-- 
-- ============================================================================

