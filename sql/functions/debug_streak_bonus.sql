-- ============================================================================
-- FUNÇÃO: debug_streak_bonus
-- ============================================================================

CREATE OR REPLACE FUNCTION public.debug_streak_bonus(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_milestone INTEGER;
    v_points_period INTEGER;
    v_days_back INTEGER;
    v_check_days INTEGER;
    v_multiplier DECIMAL(3,2);
    v_already_applied BOOLEAN;
    v_debug_info JSON;
BEGIN
    -- PASSO 1: Buscar streak atual
    SELECT current_streak INTO v_current_streak
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- PASSO 2: Verificar se tem streak suficiente
    IF v_current_streak IS NULL OR v_current_streak < 7 THEN
        RETURN json_build_object(
            'step', 'check_streak',
            'error', 'Streak insuficiente',
            'current_streak', v_current_streak,
            'required', 7
        );
    END IF;
    
    -- PASSO 3: Determinar milestone
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE 
            RETURN json_build_object(
                'step', 'determine_milestone',
                'error', 'Nenhum milestone atingido',
                'current_streak', v_current_streak
            );
    END CASE;
    
    -- PASSO 4: Calcular parâmetros do bônus
    CASE v_milestone
        WHEN 7 THEN 
            v_multiplier := 1.2;
            v_days_back := 7;
            v_check_days := 10;
        WHEN 30 THEN 
            v_multiplier := 1.5;
            v_days_back := 30;
            v_check_days := 35;
        WHEN 182 THEN 
            v_multiplier := 1.8;
            v_days_back := 182;
            v_check_days := 190;
        WHEN 365 THEN 
            v_multiplier := 2.0;
            v_days_back := 365;
            v_check_days := 370;
    END CASE;
    
    -- PASSO 5: Calcular pontos do período
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction');
    
    -- PASSO 6: Calcular bônus
    v_bonus_points := ROUND(v_points_period * (v_multiplier - 1));
    
    -- PASSO 7: Verificar se já foi aplicado NOS ÚLTIMOS X DIAS
    SELECT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
        AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_check_days)  -- ← MUDANÇA AQUI
    ) INTO v_already_applied;
    
    -- PASSO 8: Retornar todas as informações
    RETURN json_build_object(
        'step', 'complete',
        'current_streak', v_current_streak,
        'milestone', v_milestone,
        'days_back', v_days_back,
        'check_days', v_check_days,
        'multiplier', v_multiplier,
        'points_period', v_points_period,
        'calculation', v_points_period || ' × (' || v_multiplier || ' - 1) = ' || v_points_period || ' × ' || (v_multiplier - 1) || ' = ' || v_bonus_points,
        'bonus_points', v_bonus_points,
        'already_applied', v_already_applied,
        'already_applied_info', 'Verificado nos últimos ' || v_check_days || ' dias',
        'will_insert', (v_bonus_points > 0 AND NOT v_already_applied),
        'reason_not_insert', CASE 
            WHEN v_bonus_points <= 0 THEN 'Bônus é 0 ou negativo'
            WHEN v_already_applied THEN 'Bônus já foi aplicado nos últimos ' || v_check_days || ' dias'
            ELSE 'OK - Será inserido'
        END
    );
END;
$function$

