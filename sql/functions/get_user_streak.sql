-- ============================================================================
-- FUNÇÃO: get_user_streak
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_streak(p_user_id uuid)
 RETURNS TABLE(current_streak integer, longest_streak integer, last_activity_date date, next_milestone integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Apenas ler dados de user_streaks, SEM atualizar
    RETURN QUERY
    SELECT 
        user_streaks.current_streak,
        user_streaks.longest_streak,
        user_streaks.last_activity_date,
        user_streaks.next_milestone
    FROM user_streaks
    WHERE user_streaks.user_id = p_user_id;
    
    -- Se não existe registro, retornar valores zerados
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 0, NULL::DATE, 7;
    END IF;
END;
$function$

