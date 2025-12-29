-- ============================================================================
-- FUNÇÃO: check_points_before_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_points_before_deletion()
 RETURNS TABLE(user_id uuid, points_history_count bigint, points_history_total bigint, user_points_total integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ph.user_id,
        COUNT(ph.id) as points_history_count,
        COALESCE(SUM(ph.points_earned), 0) as points_history_total,
        COALESCE(up.total_points, 0) as user_points_total
    FROM public.points_history ph
    LEFT JOIN public.user_points up ON ph.user_id = up.user_id
    WHERE ph.user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
    GROUP BY ph.user_id, up.total_points
    ORDER BY ph.user_id;
END;
$function$

