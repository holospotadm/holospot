-- ============================================================================
-- FUNÇÃO: get_user_streak_info
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_streak_info(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak_info RECORD;
    v_total_bonuses INTEGER;
    v_recent_bonuses JSON;
BEGIN
    -- Buscar informações do streak
    SELECT current_streak, next_milestone, last_activity_date, updated_at
    INTO v_streak_info
    FROM public.user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não existe, retornar valores padrão
    IF NOT FOUND THEN
        RETURN json_build_object(
            'current_streak', 0,
            'next_milestone', 7,
            'total_bonuses', 0,
            'recent_bonuses', '[]'::json
        );
    END IF;
    
    -- Calcular total de bonus já recebidos
    SELECT COALESCE(SUM(points_earned), 0)
    INTO v_total_bonuses
    FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type LIKE 'streak_bonus%';
    
    -- Buscar bonus recentes
    SELECT json_agg(
        json_build_object(
            'milestone', REPLACE(REPLACE(action_type, 'streak_bonus_', ''), 'd', ''),
            'points', points_earned,
            'date', created_at
        ) ORDER BY created_at DESC
    )
    INTO v_recent_bonuses
    FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type LIKE 'streak_bonus%'
    AND created_at >= NOW() - INTERVAL '30 days'
    LIMIT 10;
    
    RETURN json_build_object(
        'current_streak', v_streak_info.current_streak,
        'next_milestone', v_streak_info.next_milestone,
        'last_activity_date', v_streak_info.last_activity_date,
        'total_bonuses', v_total_bonuses,
        'recent_bonuses', COALESCE(v_recent_bonuses, '[]'::json)
    );
END;
$function$

