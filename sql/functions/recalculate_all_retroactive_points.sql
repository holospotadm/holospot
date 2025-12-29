-- ============================================================================
-- FUNÇÃO: recalculate_all_retroactive_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_retroactive_points()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user RECORD;
    v_user_result JSON;
    v_results JSON[] := '{}';
    v_total_users INTEGER := 0;
    v_success_count INTEGER := 0;
    v_final_result JSON;
BEGIN
    -- Processar cada usuário
    FOR v_user IN 
        SELECT user_id FROM public.user_points
    LOOP
        v_total_users := v_total_users + 1;
        
        -- Recalcular pontos do usuário
        SELECT recalculate_user_retroactive_points(v_user.user_id) INTO v_user_result;
        
        -- Adicionar resultado ao array
        v_results := array_append(v_results, v_user_result);
        
        -- Contar sucessos
        IF (v_user_result->>'success')::boolean THEN
            v_success_count := v_success_count + 1;
        END IF;
    END LOOP;
    
    -- Retornar resultado final
    v_final_result := json_build_object(
        'total_users_processed', v_total_users,
        'successful_recalculations', v_success_count,
        'failed_recalculations', v_total_users - v_success_count,
        'user_results', array_to_json(v_results)
    );
    
    RETURN v_final_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$

