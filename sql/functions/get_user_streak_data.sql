-- ============================================================================
-- FUNÇÃO: get_user_streak_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_streak_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak_data RECORD;
BEGIN
    SELECT 
        current_streak,
        longest_streak,
        next_milestone,
        last_activity_date
    INTO v_streak_data
    FROM public.user_streaks
    WHERE user_id = p_user_id;
    
    -- Se não encontrou, retornar dados padrão
    IF NOT FOUND THEN
        RETURN json_build_object(
            'current_streak', 0,
            'longest_streak', 0,
            'next_milestone', 7,
            'last_activity_date', NULL
        );
    END IF;
    
    RETURN json_build_object(
        'current_streak', v_streak_data.current_streak,
        'longest_streak', v_streak_data.longest_streak,
        'next_milestone', v_streak_data.next_milestone,
        'last_activity_date', v_streak_data.last_activity_date
    );
END;
$function$

