-- ============================================================================
-- FUNÇÃO: get_global_ranking
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_global_ranking(p_limit integer DEFAULT 50)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN (
        SELECT json_agg(json_build_object(
            'user_id', ur.user_id,
            'total_points', ur.total_points,
            'level_name', ur.level_name,
            'level_icon', ur.level_icon,
            'level_color', ur.level_color,
            'rank_position', ur.rank_position
        ) ORDER BY ur.rank_position)
        FROM public.user_ranking ur
        LIMIT p_limit
    );
END;
$function$

