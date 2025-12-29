-- ============================================================================
-- FUNÇÃO: add_points_to_user_v3
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_action_type character varying, p_points integer, p_reference_id uuid DEFAULT NULL::uuid, p_reference_type character varying DEFAULT NULL::character varying)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_current_points INTEGER;
    v_new_total_points INTEGER;
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_level_up BOOLEAN := false;
    v_result JSON;
BEGIN
    -- Inicializar pontos do usuário se não existir
    PERFORM initialize_user_points(p_user_id);
    
    -- Obter pontos atuais
    SELECT total_points, level_id INTO v_current_points, v_old_level
    FROM public.user_points 
    WHERE user_id = p_user_id;
    
    -- Calcular novos pontos
    v_new_total_points := v_current_points + p_points;
    
    -- Calcular novo nível
    v_new_level := calculate_user_level(v_new_total_points);
    
    -- Verificar se subiu de nível
    IF v_new_level > v_old_level THEN
        v_level_up := true;
    END IF;
    
    -- Atualizar pontos do usuário
    UPDATE public.user_points 
    SET 
        total_points = v_new_total_points,
        level_id = v_new_level,
        points_to_next_level = CASE 
            WHEN v_new_level < 10 THEN 
                (SELECT points_required FROM public.levels WHERE id = v_new_level + 1) - v_new_total_points
            ELSE 0
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Registrar no histórico
    INSERT INTO public.points_history (user_id, action_type, points_earned, reference_id, reference_type)
    VALUES (p_user_id, p_action_type, p_points, p_reference_id, p_reference_type);
    
    -- Verificar badges após adicionar pontos
    PERFORM check_and_award_badges(p_user_id);
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'points_added', p_points,
        'total_points', v_new_total_points,
        'old_level', v_old_level,
        'new_level', v_new_level,
        'level_up', v_level_up
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$

