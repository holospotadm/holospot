-- ============================================================================
-- MIGRATION: Debug Streak Bonus - Retornar informações de debug
-- ============================================================================
-- OBJETIVO: Criar função que retorna JSON com todas as informações de debug
-- para identificar exatamente onde está falhando
-- ============================================================================

-- ============================================================================
-- FUNÇÃO DE DEBUG: Retorna JSON com informações detalhadas
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
        WHEN 30 THEN 
            v_multiplier := 1.5;
            v_days_back := 30;
        WHEN 182 THEN 
            v_multiplier := 1.8;
            v_days_back := 182;
        WHEN 365 THEN 
            v_multiplier := 2.0;
            v_days_back := 365;
    END CASE;
    
    -- PASSO 5: Calcular pontos do período
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction');
    
    -- PASSO 6: Calcular bônus
    v_bonus_points := ROUND(v_points_period * (v_multiplier - 1));
    
    -- PASSO 7: Verificar se já foi aplicado
    SELECT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
    ) INTO v_already_applied;
    
    -- PASSO 8: Retornar todas as informações
    RETURN json_build_object(
        'step', 'complete',
        'current_streak', v_current_streak,
        'milestone', v_milestone,
        'days_back', v_days_back,
        'multiplier', v_multiplier,
        'points_period', v_points_period,
        'calculation', v_points_period || ' × (' || v_multiplier || ' - 1) = ' || v_points_period || ' × ' || (v_multiplier - 1) || ' = ' || v_bonus_points,
        'bonus_points', v_bonus_points,
        'already_applied', v_already_applied,
        'will_insert', (v_bonus_points > 0 AND NOT v_already_applied),
        'reason_not_insert', CASE 
            WHEN v_bonus_points <= 0 THEN 'Bônus é 0 ou negativo'
            WHEN v_already_applied THEN 'Bônus já foi aplicado antes'
            ELSE 'OK - Será inserido'
        END
    );
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS
-- ============================================================================

COMMENT ON FUNCTION public.debug_streak_bonus(uuid) IS 
'Função de debug que retorna JSON com todas as informações do cálculo de bônus de streak.
Use: SELECT debug_streak_bonus(''seu-user-id'');';

-- ============================================================================
-- INSTRUÇÕES DE USO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Função debug_streak_bonus criada com sucesso!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 COMO USAR:';
    RAISE NOTICE '1. Execute no Supabase SQL Editor:';
    RAISE NOTICE '   SELECT debug_streak_bonus(''seu-user-id'');';
    RAISE NOTICE '';
    RAISE NOTICE '2. Ou no frontend (console do navegador):';
    RAISE NOTICE '   const { data } = await supabase.rpc(''debug_streak_bonus'', { p_user_id: currentUser.id });';
    RAISE NOTICE '   console.log(data);';
    RAISE NOTICE '';
    RAISE NOTICE '3. O retorno mostrará EXATAMENTE onde está o problema:';
    RAISE NOTICE '   - Streak atual';
    RAISE NOTICE '   - Milestone detectado';
    RAISE NOTICE '   - Pontos do período';
    RAISE NOTICE '   - Cálculo do bônus passo a passo';
    RAISE NOTICE '   - Se será inserido ou não';
    RAISE NOTICE '   - Motivo se não for inserido';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
