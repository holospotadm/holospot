-- ============================================================================
-- FUNÇÃO: test_points_integrity
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_points_integrity()
 RETURNS TABLE(user_id uuid, points_history_total integer, user_points_total integer, difference integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ph.user_id,
        COALESCE(SUM(ph.points_earned), 0)::INTEGER as points_history_total,
        COALESCE(up.total_points, 0)::INTEGER as user_points_total,
        (COALESCE(SUM(ph.points_earned), 0) - COALESCE(up.total_points, 0))::INTEGER as difference
    FROM public.points_history ph
    FULL OUTER JOIN public.user_points up ON ph.user_id = up.user_id
    GROUP BY ph.user_id, up.total_points
    HAVING COALESCE(SUM(ph.points_earned), 0) != COALESCE(up.total_points, 0)
    ORDER BY difference DESC;
END;
$function$

