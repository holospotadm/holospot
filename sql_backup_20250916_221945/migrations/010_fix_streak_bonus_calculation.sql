-- ============================================================================
-- MIGRATION 010: CORREÇÃO DO CÁLCULO DE BÔNUS DE STREAK
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Corrigir cálculo de bônus para usar apenas pontos dos últimos X dias
-- Problema: Função atual calcula sobre TODOS os pontos, deveria ser só dos últimos dias
-- ============================================================================

-- CORREÇÃO: NOVA FUNÇÃO DE CÁLCULO DE BÔNUS DE STREAK
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_user_id uuid, p_milestone integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_multiplier DECIMAL(3,2);
    v_days_back INTEGER;
    v_points_period INTEGER;
    v_bonus INTEGER;
BEGIN
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
    
    -- Se não é um milestone válido, retornar 0
    IF v_days_back = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular pontos dos últimos X dias
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type != 'streak_bonus_retroactive'; -- Excluir bônus anteriores
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE 'Cálculo de bônus: User % - Milestone % dias - Pontos período: % - Bônus: %', 
        p_user_id, p_milestone, v_points_period, v_bonus;
    
    RETURN v_bonus;
END;
$$;

-- ATUALIZAR FUNÇÃO DE APLICAÇÃO DE BÔNUS RETROATIVO
-- ============================================================================

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_milestone INTEGER;
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
    
    -- Calcular bônus usando função corrigida (agora recebe user_id)
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RETURN;
    END IF;
    
    -- Verificar se já foi aplicado este bônus
    IF NOT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
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
        PERFORM update_user_total_points(p_user_id);
        
        RAISE NOTICE 'Bônus retroativo aplicado: User % - Streak % dias - Milestone % - Bônus % pontos', 
            p_user_id, v_current_streak, v_milestone, v_bonus_points;
    END IF;
END;
$$;

-- RECALCULAR BÔNUS PARA USUÁRIOS QUE JÁ RECEBERAM (CORREÇÃO)
-- ============================================================================

DO $$
DECLARE
    user_record RECORD;
    v_old_bonus INTEGER;
    v_new_bonus INTEGER;
    v_difference INTEGER;
BEGIN
    -- Para cada usuário que já recebeu bônus retroativo
    FOR user_record IN 
        SELECT DISTINCT 
            ph.user_id,
            ph.points_earned as old_bonus,
            CAST(REPLACE(ph.reference_type, 'milestone_', '') AS INTEGER) as milestone
        FROM points_history ph
        WHERE ph.action_type = 'streak_bonus_retroactive'
    LOOP
        -- Calcular novo bônus correto
        v_new_bonus := calculate_streak_bonus(user_record.user_id, user_record.milestone);
        v_old_bonus := user_record.old_bonus;
        v_difference := v_new_bonus - v_old_bonus;
        
        -- Se há diferença, aplicar correção
        IF v_difference != 0 THEN
            -- Adicionar entrada de correção
            INSERT INTO points_history (
                user_id, 
                points_earned, 
                action_type, 
                reference_id, 
                reference_type,
                created_at
            ) VALUES (
                user_record.user_id,
                v_difference,
                'streak_bonus_correction',
                user_record.user_id,
                'milestone_' || user_record.milestone::text || '_correction',
                NOW()
            );
            
            -- Atualizar total de pontos
            PERFORM update_user_total_points(user_record.user_id);
            
            RAISE NOTICE 'Correção aplicada: User % - Bônus antigo: % - Bônus novo: % - Diferença: %', 
                user_record.user_id, v_old_bonus, v_new_bonus, v_difference;
        END IF;
    END LOOP;
END $$;

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '🎉 MIGRATION 010 CONCLUÍDA - CORREÇÃO DE CÁLCULO DE BÔNUS';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CORREÇÃO 1: Função calculate_streak_bonus corrigida';
    RAISE NOTICE '   - Agora calcula sobre pontos dos últimos X dias apenas';
    RAISE NOTICE '   - 7 dias: pontos dos últimos 7 dias × 20%%';
    RAISE NOTICE '   - 30 dias: pontos dos últimos 30 dias × 50%%';
    RAISE NOTICE '   - 182 dias: pontos dos últimos 182 dias × 80%%';
    RAISE NOTICE '   - 365 dias: pontos dos últimos 365 dias × 100%%';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CORREÇÃO 2: Função apply_streak_bonus_retroactive atualizada';
    RAISE NOTICE '   - Usa nova lógica de cálculo';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CORREÇÃO 3: Bônus incorretos recalculados e corrigidos';
    RAISE NOTICE '   - Usuários que receberam bônus sobre todos os pontos';
    RAISE NOTICE '   - Agora recebem correção (positiva ou negativa)';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 RESULTADO: Bônus agora calculado corretamente!';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

