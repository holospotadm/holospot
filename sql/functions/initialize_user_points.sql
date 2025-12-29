-- ============================================================================
-- FUNÇÃO: initialize_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.initialize_user_points(user_uuid uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level)
    VALUES (user_uuid, 0, 1, 50)
    ON CONFLICT (user_id) DO NOTHING;
END;
$function$

