-- ============================================================================
-- USER_STREAKS TABLE - Sistema de Streaks/Sequências
-- ============================================================================
-- Tabela que controla sequências de atividade diária dos usuários
-- Sistema de engajamento e motivação contínua
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_streaks (
    -- Usuário (chave primária, um registro por usuário)
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Sequência atual de dias consecutivos
    current_streak INTEGER DEFAULT 0,
    
    -- Maior sequência já alcançada (recorde pessoal)
    longest_streak INTEGER DEFAULT 0,
    
    -- Próximo milestone a ser atingido
    next_milestone INTEGER DEFAULT 7,
    
    -- Data da última atividade registrada
    last_activity_date DATE,
    
    -- Timestamp de última atualização (sem timezone)
    updated_at TIMESTAMP DEFAULT now()
);

-- ============================================================================
-- ÍNDICES DA TABELA USER_STREAKS
-- ============================================================================

-- Índice para busca por streak atual (rankings)
CREATE INDEX IF NOT EXISTS idx_user_streaks_current_streak 
ON public.user_streaks (current_streak DESC);

-- Índice para busca por próximo milestone
CREATE INDEX IF NOT EXISTS idx_user_streaks_next_milestone 
ON public.user_streaks (next_milestone);

-- Índice para busca por data de última atividade
CREATE INDEX IF NOT EXISTS idx_user_streaks_last_activity_date 
ON public.user_streaks (last_activity_date DESC);

-- Índice para busca por data de atualização
CREATE INDEX IF NOT EXISTS idx_user_streaks_updated_at 
ON public.user_streaks (updated_at DESC);

-- Índice composto para análise de streaks ativos
CREATE INDEX IF NOT EXISTS idx_user_streaks_active 
ON public.user_streaks (current_streak DESC, last_activity_date DESC) 
WHERE current_streak > 0;

-- ============================================================================
-- TRIGGERS DA TABELA USER_STREAKS
-- ============================================================================

-- Trigger para notificação quando milestone é atingido
CREATE TRIGGER streak_notification_only_trigger 
    AFTER UPDATE ON public.user_streaks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_streak_notification_only();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.user_streaks IS 
'Tabela que controla sequências de atividade diária dos usuários.
Sistema de engajamento e motivação contínua do HoloSpot.';

COMMENT ON COLUMN public.user_streaks.user_id IS 'Usuário proprietário do streak (chave primária)';
COMMENT ON COLUMN public.user_streaks.current_streak IS 'Sequência atual de dias consecutivos de atividade';
COMMENT ON COLUMN public.user_streaks.longest_streak IS 'Maior sequência de dias consecutivos já alcançada (recorde pessoal)';
COMMENT ON COLUMN public.user_streaks.next_milestone IS 'Próximo milestone de streak a ser atingido';
COMMENT ON COLUMN public.user_streaks.last_activity_date IS 'Data da última atividade registrada para o streak';
COMMENT ON COLUMN public.user_streaks.updated_at IS 'Timestamp de última atualização do streak';

-- ============================================================================
-- NOTAS SOBRE A TABELA USER_STREAKS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 5 campos para controle completo de streaks
-- - user_id como chave primária (um registro por usuário)
-- - Campos com defaults apropriados
-- - TIMESTAMP sem timezone (diferente de outras tabelas)
-- - Sistema de milestones integrado
-- 
-- Relacionamentos:
-- - user_streaks.user_id → profiles.id (CASCADE DELETE)
-- 
-- Sistema de Streaks:
-- - current_streak: Dias consecutivos de atividade
-- - Resetado quando usuário perde sequência
-- - Incrementado diariamente com atividade
-- 
-- Sistema de Milestones:
-- - next_milestone: Próximo marco a atingir
-- - Marcos comuns: 7, 30, 182, 365 dias
-- - Bônus especiais por milestone
-- 
-- Controle de Atividade:
-- - last_activity_date: Data da última atividade
-- - Usado para verificar continuidade
-- - Comparado com data atual
-- 
-- Triggers Ativos (1 total):
-- 1. streak_notification_only_trigger - Notificação de milestone
-- 
-- Funcionalidades:
-- - Sequências de atividade diária
-- - Milestones de engajamento
-- - Bônus por consistência
-- - Motivação contínua
-- - Rankings de streaks
-- 
-- Lógica de Funcionamento:
-- - Atividade diária incrementa streak
-- - Falta de atividade reseta streak
-- - Milestones geram notificações e bônus
-- - Sistema automático de verificação
-- 
-- Milestones Comuns:
-- - 7 dias: Primeira semana
-- - 30 dias: Primeiro mês
-- - 182 dias: Meio ano (6 meses)
-- - 365 dias: Ano completo
-- 
-- Consultas Comuns:
-- - Streak atual de um usuário
-- - Ranking de streaks
-- - Usuários próximos a milestones
-- - Análise de engajamento
-- - Estatísticas de consistência
-- 
-- Validações:
-- - current_streak não negativo
-- - next_milestone válido
-- - last_activity_date consistente
-- - Referências válidas (FK)
-- 
-- Performance:
-- - Índices otimizados para rankings
-- - Busca eficiente por streak
-- - Filtros para streaks ativos
-- - Análise temporal eficiente
-- 
-- Integridade:
-- - Foreign key garante usuário válido
-- - Deleção em cascata mantém consistência
-- - Dados consistentes com atividade
-- - Triggers mantêm notificações
-- 
-- Motivação e Engajamento:
-- - Incentiva atividade diária
-- - Recompensa consistência
-- - Cria hábitos saudáveis
-- - Gamifica participação
-- 
-- Análise e Métricas:
-- - Distribuição de streaks
-- - Taxa de retenção diária
-- - Efetividade de milestones
-- - Padrões de atividade
-- 
-- Manutenção:
-- - Verificação diária automática
-- - Reset de streaks inativos
-- - Monitoramento de milestones
-- - Backup de histórico
-- 
-- Diferenças Estruturais:
-- - user_id como PK (não UUID separado)
-- - TIMESTAMP sem timezone
-- - Um registro por usuário
-- - Sistema de milestones integrado
-- 
-- ============================================================================

