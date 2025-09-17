-- ============================================================================
-- AUXILIARY NOTIFICATION FUNCTIONS - Funções Auxiliares de Notificação
-- ============================================================================
-- Funções auxiliares chamadas pelas funções principais de notificação
-- Estas funções estavam sendo chamadas mas não existiam
-- ============================================================================

-- ============================================================================
-- CREATE_SINGLE_NOTIFICATION - Função Auxiliar Principal
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_single_notification(
    p_user_id UUID,
    p_from_user_id UUID,
    p_type TEXT,
    p_message TEXT,
    p_priority INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
BEGIN
    -- Criar notificação simples sem agrupamento
    INSERT INTO public.notifications (
        user_id,
        from_user_id,
        type,
        message,
        read,
        created_at,
        group_key,
        group_count,
        group_data
    ) VALUES (
        p_user_id,
        p_from_user_id,
        p_type,
        p_message,
        false,
        NOW(),
        NULL,  -- Sem agrupamento para notificações simples
        1,
        NULL
    );
    
    RAISE NOTICE 'NOTIFICAÇÃO CRIADA: % para %', p_type, p_user_id;
END;
$function$;

-- ============================================================================
-- NOTIFY_STREAK_MILESTONE_CORRECT - Função Específica para Streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_streak_milestone_correct(
    p_user_id UUID,
    p_milestone_days INTEGER,
    p_bonus_points INTEGER DEFAULT 0
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
DECLARE
    message_text TEXT;
    milestone_emoji TEXT;
BEGIN
    -- Definir emoji baseado no milestone
    CASE p_milestone_days
        WHEN 7 THEN milestone_emoji := '🔥';
        WHEN 30 THEN milestone_emoji := '⚡';
        WHEN 182 THEN milestone_emoji := '🌟';
        WHEN 365 THEN milestone_emoji := '👑';
        ELSE milestone_emoji := '🎯';
    END CASE;
    
    -- Montar mensagem baseada nos pontos bônus
    IF p_bonus_points > 0 THEN
        message_text := milestone_emoji || ' Incrível! Você atingiu ' || p_milestone_days || ' dias de sequência e ganhou ' || p_bonus_points || ' pontos bônus';
    ELSE
        message_text := milestone_emoji || ' Parabéns! Você atingiu ' || p_milestone_days || ' dias de sequência';
    END IF;
    
    -- Criar notificação usando função auxiliar
    PERFORM create_single_notification(
        p_user_id,
        NULL,  -- Notificação do sistema
        'streak_milestone',
        message_text,
        3  -- Alta prioridade
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', p_milestone_days, p_user_id, p_bonus_points;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.create_single_notification(UUID, UUID, TEXT, TEXT, INTEGER) IS 
'Função auxiliar para criar notificações simples sem agrupamento.
Usada por badges, streaks e outras notificações do sistema.
Parâmetros: user_id, from_user_id, type, message, priority';

COMMENT ON FUNCTION public.notify_streak_milestone_correct(UUID, INTEGER, INTEGER) IS 
'Função específica para notificar milestones de streak.
Inclui emojis apropriados e informações de pontos bônus.
Parâmetros: user_id, milestone_days, bonus_points';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES AUXILIARES
-- ============================================================================
-- 
-- create_single_notification():
-- - Função base para notificações simples
-- - Sem sistema de agrupamento (group_key = NULL)
-- - Usada por badges, streaks, níveis
-- - Prioridade configurável (1=baixa, 2=média, 3=alta)
-- 
-- notify_streak_milestone_correct():
-- - Específica para milestones de streak
-- - Emojis diferentes por milestone (7d=🔥, 30d=⚡, 182d=🌟, 365d=👑)
-- - Inclui informações de pontos bônus quando aplicável
-- - Alta prioridade (3) por padrão
-- 
-- Tipos de Notificação Suportados:
-- - badge_earned: Badges conquistados
-- - streak_milestone: Milestones de sequência
-- - level_up: Mudança de nível (será implementado)
-- 
-- Prioridades:
-- - 1: Baixa (reações, comentários simples)
-- - 2: Média (follows, feedbacks)
-- - 3: Alta (badges, streaks, níveis, menções)
-- 
-- ============================================================================

