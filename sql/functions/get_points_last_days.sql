-- ============================================================================
-- FUNÇÃO: get_points_last_days
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_points_last_days(p_user_id uuid, p_days integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(points_earned), 0)
        FROM public.points_history 
        WHERE user_id = p_user_id 
        AND created_at >= CURRENT_DATE - INTERVAL '1 day' * p_days
        AND action_type NOT LIKE 'streak_bonus%' -- Excluir bonus anteriores para evitar duplicação
    );
END;
$function$

