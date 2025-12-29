-- ============================================================================
-- FUNÇÃO: apply_streak_bonus_retroactive
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
$function$

