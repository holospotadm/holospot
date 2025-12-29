-- ============================================================================
-- FUNÇÃO: update_user_streak_with_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id uuid)
 RETURNS TABLE(current_streak integer, longest_streak integer, last_activity_date date, milestone_reached boolean, milestone_value integer, bonus_points integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_result RECORD;
BEGIN
    -- Chamar função incremental e pegar resultado
    SELECT * INTO v_result FROM update_user_streak_incremental(p_user_id);
    
    -- Retornar TODOS os 6 campos
    RETURN QUERY SELECT 
        v_result.current_streak,
        v_result.longest_streak,
        v_result.last_activity_date,
        v_result.milestone_reached,
        v_result.milestone_value,  -- ← ADICIONADO
        v_result.bonus_points;
END;
$function$

