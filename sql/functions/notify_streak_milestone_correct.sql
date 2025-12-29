-- ============================================================================
-- FUNÇÃO: notify_streak_milestone_correct
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_streak_milestone_correct(p_user_id uuid, p_milestone_days integer, p_bonus_points integer DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
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
$function$

