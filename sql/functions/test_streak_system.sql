-- ============================================================================
-- FUNÇÃO: test_streak_system
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_streak_system(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result JSON;
BEGIN
    -- Atualizar streak
    SELECT update_user_streak(p_user_id) INTO v_result;
    
    RETURN json_build_object(
        'test_completed', true,
        'user_id', p_user_id,
        'streak_result', v_result,
        'timestamp', NOW()
    );
END;
$function$

