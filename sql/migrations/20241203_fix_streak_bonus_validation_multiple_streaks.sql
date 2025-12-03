-- ============================================================================
-- MIGRATION: Fix Streak Bonus Validation for Multiple Streaks
-- ============================================================================
-- PROBLEMA:
-- - Validação atual impede bônus duplicado PARA SEMPRE
-- - Mas usuário pode quebrar streak e começar novo
-- - Quando atingir 7 dias novamente, DEVE receber bônus de novo
--
-- SOLUÇÃO:
-- - Verificar se bônus já foi aplicado nos últimos X dias
-- - Para milestone de 7 dias: verificar últimos 10 dias
-- - Para milestone de 30 dias: verificar últimos 35 dias
-- - Para milestone de 182 dias: verificar últimos 190 dias
-- - Para milestone de 365 dias: verificar últimos 370 dias
--
-- LÓGICA:
-- - Se quebrou streak e passou tempo suficiente, pode receber novamente
-- - Se ainda está no mesmo streak, não duplicar
-- ============================================================================

-- ============================================================================
-- FUNÇÃO: apply_streak_bonus_retroactive (CORRIGIDA)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_milestone INTEGER;
    v_check_days INTEGER;
BEGIN
    -- Buscar streak atual do usuário
    SELECT current_streak INTO v_current_streak
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não tem streak, não aplicar bônus
    IF v_current_streak IS NULL OR v_current_streak < 7 THEN
        RETURN;
    END IF;
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE RETURN; -- Não atingiu milestone
    END CASE;
    
    -- Determinar período de verificação (milestone + margem de segurança)
    CASE v_milestone
        WHEN 7 THEN v_check_days := 10;
        WHEN 30 THEN v_check_days := 35;
        WHEN 182 THEN v_check_days := 190;
        WHEN 365 THEN v_check_days := 370;
    END CASE;
    
    -- Calcular bônus usando função corrigida
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RETURN;
    END IF;
    
    -- ✅ CORREÇÃO: Verificar se já foi aplicado nos ÚLTIMOS X DIAS (não para sempre)
    -- Isso permite que usuário receba bônus novamente em streaks diferentes
    IF NOT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
        AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_check_days)  -- ← MUDANÇA AQUI
    ) THEN
        -- Aplicar bônus retroativo
        INSERT INTO points_history (
            user_id, 
            points_earned, 
            action_type, 
            reference_id, 
            reference_type,
            created_at
        ) VALUES (
            p_user_id,
            v_bonus_points,
            'streak_bonus_retroactive',
            p_user_id,
            'milestone_' || v_milestone::text,
            NOW()
        );
        
        -- Atualizar total de pontos
        PERFORM recalculate_user_points_secure(p_user_id);
        
        RAISE NOTICE '✅ Bônus retroativo aplicado: User % - Streak % dias - Milestone % - Bônus % pontos', 
            p_user_id, v_current_streak, v_milestone, v_bonus_points;
    ELSE
        RAISE NOTICE '⚠️ Bônus já aplicado nos últimos % dias para milestone %, pulando', 
            v_check_days, v_milestone;
    END IF;
END;
$function$;

-- ============================================================================
-- FUNÇÃO DE DEBUG: Atualizar também
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
$function$;

-- ============================================================================
-- COMENTÁRIOS
-- ============================================================================

COMMENT ON FUNCTION public.apply_streak_bonus_retroactive(uuid) IS 
'Aplica bônus retroativo quando milestone é atingido.
CORRIGIDO: Permite bônus em streaks diferentes (verifica últimos X dias, não para sempre).';

COMMENT ON FUNCTION public.debug_streak_bonus(uuid) IS 
'Função de debug que retorna JSON com todas as informações do cálculo de bônus.
CORRIGIDO: Mostra período de verificação (últimos X dias).';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Funções atualizadas com sucesso!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 MUDANÇAS:';
    RAISE NOTICE '- Bônus agora pode ser aplicado em streaks diferentes';
    RAISE NOTICE '- Verificação nos últimos X dias (não para sempre):';
    RAISE NOTICE '  * 7 dias → últimos 10 dias';
    RAISE NOTICE '  * 30 dias → últimos 35 dias';
    RAISE NOTICE '  * 182 dias → últimos 190 dias';
    RAISE NOTICE '  * 365 dias → últimos 370 dias';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Usuário pode receber bônus novamente em novo streak!';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
