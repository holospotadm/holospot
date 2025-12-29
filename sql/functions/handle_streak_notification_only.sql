-- ============================================================================
-- FUNÇÃO: handle_streak_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_streak_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    milestone_reached INTEGER;
    bonus_points INTEGER;
BEGIN
    -- CORREÇÃO: Verificar se current_streak ATINGIU um milestone
    -- Em vez de verificar mudança de next_milestone
    
    -- Verificar se atingiu milestone de 7 dias
    IF OLD.current_streak < 7 AND NEW.current_streak >= 7 THEN
        milestone_reached := 7;
    -- Verificar se atingiu milestone de 30 dias
    ELSIF OLD.current_streak < 30 AND NEW.current_streak >= 30 THEN
        milestone_reached := 30;
    -- Verificar se atingiu milestone de 182 dias
    ELSIF OLD.current_streak < 182 AND NEW.current_streak >= 182 THEN
        milestone_reached := 182;
    -- Verificar se atingiu milestone de 365 dias
    ELSIF OLD.current_streak < 365 AND NEW.current_streak >= 365 THEN
        milestone_reached := 365;
    ELSE
        -- Nenhum milestone atingido, não fazer nada
        RETURN NEW;
    END IF;
    
    -- Buscar pontos bônus do histórico (se existir)
    SELECT COALESCE(points_earned, 0) INTO bonus_points
    FROM public.points_history 
    WHERE user_id = NEW.user_id 
    AND action_type = 'streak_bonus_' || milestone_reached || 'd'
    AND created_at >= NOW() - INTERVAL '1 hour'
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Notificar milestone
    PERFORM notify_streak_milestone_correct(
        NEW.user_id, 
        milestone_reached, 
        COALESCE(bonus_points, 0)
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', milestone_reached, NEW.user_id, bonus_points;
    
    RETURN NEW;
END;
$function$

