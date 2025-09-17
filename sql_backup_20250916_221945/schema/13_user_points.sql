-- ============================================================================
-- USER_POINTS TABLE - Pontuação Total dos Usuários
-- ============================================================================
-- Tabela que mantém o total de pontos e nível atual de cada usuário
-- Sistema de gamificação e progressão
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_points (
    -- Identificador único do registro
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Usuário (obrigatório)
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Total de pontos acumulados
    total_points INTEGER DEFAULT 0,
    
    -- Nível atual do usuário (FK para levels)
    level_id INTEGER DEFAULT 1 REFERENCES public.levels(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Pontos necessários para o próximo nível
    points_to_next_level INTEGER DEFAULT 50,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Timestamp de última atualização
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- CONSTRAINTS DA TABELA USER_POINTS
-- ============================================================================

-- Constraint única para garantir um registro por usuário
ALTER TABLE public.user_points 
ADD CONSTRAINT unique_user_points 
UNIQUE (user_id);

-- Constraint para garantir pontos não negativos
ALTER TABLE public.user_points 
ADD CONSTRAINT check_total_points_non_negative 
CHECK (total_points >= 0);

-- Constraint para garantir nível válido
ALTER TABLE public.user_points 
ADD CONSTRAINT check_level_id_positive 
CHECK (level_id > 0);

-- ============================================================================
-- ÍNDICES DA TABELA USER_POINTS
-- ============================================================================

-- Índice para busca por usuário (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_user_points_user_id 
ON public.user_points (user_id);

-- Índice para ranking por pontos totais
CREATE INDEX IF NOT EXISTS idx_user_points_total_points 
ON public.user_points (total_points DESC);

-- Índice para busca por nível
CREATE INDEX IF NOT EXISTS idx_user_points_level_id 
ON public.user_points (level_id);

-- Índice para ordenação por data de atualização
CREATE INDEX IF NOT EXISTS idx_user_points_updated_at 
ON public.user_points (updated_at DESC);

-- Índice composto para ranking por nível e pontos
CREATE INDEX IF NOT EXISTS idx_user_points_level_points 
ON public.user_points (level_id DESC, total_points DESC);

-- ============================================================================
-- TRIGGERS DA TABELA USER_POINTS
-- ============================================================================

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_user_points_updated_at 
    BEFORE UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para verificação automática de badges após atualização de pontos
CREATE TRIGGER auto_badge_check_bonus_user_points 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.user_points IS 
'Tabela que mantém o total de pontos e nível atual de cada usuário.
Sistema de gamificação e progressão do HoloSpot.';

COMMENT ON COLUMN public.user_points.id IS 'Identificador único do registro de pontos';
COMMENT ON COLUMN public.user_points.user_id IS 'Usuário proprietário dos pontos (único)';
COMMENT ON COLUMN public.user_points.total_points IS 'Total de pontos acumulados pelo usuário';
COMMENT ON COLUMN public.user_points.level_id IS 'Nível atual do usuário baseado nos pontos';
COMMENT ON COLUMN public.user_points.points_to_next_level IS 'Pontos necessários para atingir o próximo nível';
COMMENT ON COLUMN public.user_points.created_at IS 'Timestamp de criação do registro';
COMMENT ON COLUMN public.user_points.updated_at IS 'Timestamp de última atualização dos pontos';

-- ============================================================================
-- NOTAS SOBRE A TABELA USER_POINTS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 7 campos para gerenciamento completo de pontuação
-- - UUID como chave primária com uuid_generate_v4()
-- - Foreign key obrigatória para profiles
-- - Campos com defaults apropriados
-- - Sistema de níveis integrado
-- 
-- Relacionamentos:
-- - user_points.user_id → profiles.id (CASCADE DELETE)
-- - Relacionamento implícito com levels via level_id
-- 
-- Sistema de Pontuação:
-- - total_points: Soma de todos os pontos ganhos
-- - Atualizado automaticamente por triggers
-- - Histórico mantido em points_history
-- 
-- Sistema de Níveis:
-- - level_id: Nível atual baseado em total_points
-- - points_to_next_level: Progresso para próximo nível
-- - Calculado automaticamente
-- 
-- Sistema de Progressão:
-- - Níveis crescentes com thresholds
-- - Progresso visível para usuários
-- - Motivação por conquistas
-- 
-- Triggers Ativos (2 total):
-- 1. update_user_points_updated_at - Atualização de timestamp
-- 2. auto_badge_check_bonus_user_points - Verificação de badges
-- 
-- Funcionalidades:
-- - Pontuação total consolidada
-- - Sistema de níveis
-- - Progresso para próximo nível
-- - Rankings de usuários
-- - Gamificação completa
-- 
-- Consultas Comuns:
-- - Pontos de um usuário específico
-- - Ranking de usuários por pontos
-- - Usuários por nível
-- - Progresso para próximo nível
-- - Estatísticas de pontuação
-- 
-- Validações:
-- - Um registro por usuário (constraint única)
-- - Pontos não negativos
-- - Nível válido (positivo)
-- - Referências válidas (FK)
-- 
-- Performance:
-- - Índices otimizados para rankings
-- - Busca eficiente por usuário
-- - Ordenação rápida por pontos
-- - Filtros por nível
-- 
-- Integridade:
-- - Foreign key garante usuário válido
-- - Constraints garantem dados válidos
-- - Deleção em cascata mantém consistência
-- - Triggers mantêm dados atualizados
-- 
-- Sincronização:
-- - Atualizada por funções de pontuação
-- - Sincronizada com points_history
-- - Recalculada quando necessário
-- - Consistência garantida
-- 
-- Gamificação:
-- - Motivação por pontos
-- - Competição saudável
-- - Progresso visível
-- - Sistema de recompensas
-- 
-- Análise e Métricas:
-- - Distribuição de pontos
-- - Progressão de usuários
-- - Engajamento por nível
-- - Efetividade da gamificação
-- 
-- Manutenção:
-- - Tabela crítica do sistema
-- - Monitoramento de consistência
-- - Recálculo periódico
-- - Backup essencial
-- 
-- ============================================================================

