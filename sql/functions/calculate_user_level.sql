-- ============================================================================
-- FUNÇÃO: calculate_user_level
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_level(user_points integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_level INTEGER;
BEGIN
    SELECT id INTO user_level
    FROM public.levels
    WHERE points_required <= user_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    RETURN COALESCE(user_level, 1);
END;
$function$

