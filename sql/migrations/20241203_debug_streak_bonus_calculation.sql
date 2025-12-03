-- ============================================================================
-- MIGRATION: Debug Streak Bonus Calculation
-- ============================================================================
-- OBJETIVO: Adicionar logs detalhados para identificar onde está falhando
-- ============================================================================

-- ============================================================================
-- FUNÇÃO 1: calculate_streak_bonus COM LOGS DETALHADOS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_user_id uuid, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
    v_days_back INTEGER;
    v_points_period INTEGER;
    v_bonus INTEGER;
BEGIN
    RAISE NOTICE '🔍 [BONUS] Iniciando cálculo - User: %, Milestone: %', p_user_id, p_milestone;
    
    -- Determinar multiplicador e período baseado no milestone
    CASE p_milestone
        WHEN 7 THEN 
            v_multiplier := 1.2;   -- +20%
            v_days_back := 7;
        WHEN 30 THEN 
            v_multiplier := 1.5;   -- +50%
            v_days_back := 30;
        WHEN 182 THEN 
            v_multiplier := 1.8;   -- +80%
            v_days_back := 182;
        WHEN 365 THEN 
            v_multiplier := 2.0;   -- +100%
            v_days_back := 365;
        ELSE 
            v_multiplier := 1.0;
            v_days_back := 0;
    END CASE;
    
    RAISE NOTICE '🔍 [BONUS] Multiplicador: %, Dias: %', v_multiplier, v_days_back;
    
    -- Se não é um milestone válido, retornar 0
    IF v_days_back = 0 THEN
        RAISE NOTICE '⚠️ [BONUS] Milestone inválido, retornando 0';
        RETURN 0;
    END IF;
    
    -- Calcular pontos dos últimos X dias (EXCLUINDO todos os tipos de bônus)
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction');
    
    RAISE NOTICE '🔍 [BONUS] Pontos do período (últimos % dias): %', v_days_back, v_points_period;
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE '🔍 [BONUS] Cálculo: % × (% - 1) = % × % = %', 
        v_points_period, v_multiplier, v_points_period, (v_multiplier - 1), v_bonus;
    
    RAISE NOTICE '✅ [BONUS] Bônus calculado: % pontos', v_bonus;
    
    RETURN v_bonus;
END;
$function$;

-- ============================================================================
-- FUNÇÃO 2: apply_streak_bonus_retroactive COM LOGS DETALHADOS
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
BEGIN
    RAISE NOTICE '🎯 [APPLY_BONUS] Iniciando aplicação de bônus - User: %', p_user_id;
    
    -- Buscar streak atual do usuário
    SELECT current_streak INTO v_current_streak
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    RAISE NOTICE '🎯 [APPLY_BONUS] Streak atual: %', v_current_streak;
    
    -- Se não tem streak, não aplicar bônus
    IF v_current_streak IS NULL OR v_current_streak < 7 THEN
        RAISE NOTICE '⚠️ [APPLY_BONUS] Streak insuficiente (% < 7), retornando', v_current_streak;
        RETURN;
    END IF;
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE 
            RAISE NOTICE '⚠️ [APPLY_BONUS] Nenhum milestone atingido, retornando';
            RETURN;
    END CASE;
    
    RAISE NOTICE '🎯 [APPLY_BONUS] Milestone determinado: % dias', v_milestone;
    
    -- Calcular bônus usando função corrigida
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    RAISE NOTICE '🎯 [APPLY_BONUS] Bônus retornado: % pontos', v_bonus_points;
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RAISE NOTICE '⚠️ [APPLY_BONUS] Bônus é 0 ou negativo (%), retornando SEM INSERIR', v_bonus_points;
        RETURN;
    END IF;
    
    -- Verificar se já foi aplicado este bônus
    IF NOT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
    ) THEN
        RAISE NOTICE '✅ [APPLY_BONUS] Bônus não aplicado antes, inserindo % pontos', v_bonus_points;
        
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
        
        RAISE NOTICE '✅ [APPLY_BONUS] Inserido no points_history com sucesso';
        
        -- Atualizar total de pontos
        PERFORM recalculate_user_points_secure(p_user_id);
        
        RAISE NOTICE '✅ [APPLY_BONUS] Pontos recalculados com sucesso';
        RAISE NOTICE '🎉 [APPLY_BONUS] BÔNUS APLICADO: User % - Streak % dias - Milestone % - Bônus % pontos', 
            p_user_id, v_current_streak, v_milestone, v_bonus_points;
    ELSE
        RAISE NOTICE '⚠️ [APPLY_BONUS] Bônus JÁ FOI APLICADO para milestone %, pulando', v_milestone;
    END IF;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS
-- ============================================================================

COMMENT ON FUNCTION public.calculate_streak_bonus(uuid, integer) IS 
'Calcula bônus de streak baseado em pontos do período. COM LOGS DETALHADOS PARA DEBUG.';

COMMENT ON FUNCTION public.apply_streak_bonus_retroactive(uuid) IS 
'Aplica bônus retroativo quando milestone é atingido. COM LOGS DETALHADOS PARA DEBUG.';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Migration executada com sucesso!';
    RAISE NOTICE '📋 Agora complete um streak de 7 dias e verifique os logs no Supabase';
    RAISE NOTICE '📋 Os logs começarão com [BONUS] e [APPLY_BONUS]';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
