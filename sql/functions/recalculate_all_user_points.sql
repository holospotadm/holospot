-- ============================================================================
-- FUNÇÃO: recalculate_all_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_user_points()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_record RECORD;
    total_users INTEGER := 0;
BEGIN
    -- Para cada usuário que tem pontos
    FOR user_record IN 
        SELECT DISTINCT user_id FROM public.points_history
    LOOP
        PERFORM update_user_total_points(user_record.user_id);
        total_users := total_users + 1;
    END LOOP;
    
    RETURN 'Recálculo concluído para ' || total_users || ' usuários';
END;
$function$

