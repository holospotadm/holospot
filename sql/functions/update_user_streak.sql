-- ============================================================================
-- FUNÇÃO: update_user_streak
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM update_user_streak_incremental(p_user_id);
    RAISE NOTICE 'Streak atualizado (incremental): User % - Streak: %, Milestone: %', 
        p_user_id, v_result.current_streak, v_result.milestone_reached;
END;
$function$

