-- ============================================================================
-- CORREÇÃO COMPLETA: SISTEMA DE PONTOS BÔNUS DE STREAK
-- ============================================================================
-- Este script corrige completamente o sistema de pontos bônus de streak:
-- 1. Credita pontos na points_history
-- 2. Atualiza total de pontos em user_points 
-- 3. Atualiza nível do usuário
-- 4. Atualiza ranking do usuário
-- ============================================================================

-- Atualizar a função update_user_streak_with_data para sistema completo
CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_old_streak INTEGER := 0;
    v_new_streak INTEGER := 0;
    v_next_milestone INTEGER := 7;
    v_milestone_reached BOOLEAN := FALSE;
    v_completed_milestone INTEGER := 0;
    v_bonus_points INTEGER := 0;
    v_points_period INTEGER := 0;
    v_user_timezone TEXT := 'America/Sao_Paulo';
    v_current_date DATE;
BEGIN
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone 
    FROM profiles WHERE id = p_user_id;
    
    -- Se não encontrar timezone, usar padrão brasileiro
    IF v_user_timezone IS NULL THEN
        v_user_timezone := 'America/Sao_Paulo';
    END IF;
    
    -- Calcular data atual no timezone do usuário
    v_current_date := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    
    -- Buscar streak atual antes da atualização
    SELECT current_streak INTO v_old_streak
    FROM user_streaks WHERE user_id = p_user_id;
    
    -- Se não existe registro, considerar streak 0
    IF v_old_streak IS NULL THEN
        v_old_streak := 0;
    END IF;
    
    -- Atualizar streak usando função existente
    PERFORM update_user_streak(p_user_id);
    
    -- Buscar dados atualizados
    SELECT current_streak, next_milestone INTO v_new_streak, v_next_milestone
    FROM user_streaks WHERE user_id = p_user_id;
    
    -- Se ainda não existe, criar registro
    IF v_new_streak IS NULL THEN
        v_new_streak := calculate_user_streak(p_user_id);
        v_next_milestone := CASE 
            WHEN v_new_streak >= 365 THEN 365
            WHEN v_new_streak >= 182 THEN 365
            WHEN v_new_streak >= 30 THEN 182
            WHEN v_new_streak >= 7 THEN 30
            ELSE 7
        END;
        
        INSERT INTO user_streaks (user_id, current_streak, next_milestone, last_activity_date, updated_at)
        VALUES (p_user_id, v_new_streak, v_next_milestone, v_current_date, NOW());
    END IF;
    
    -- Verificar se atingiu milestone (apenas se streak aumentou)
    IF v_new_streak > v_old_streak THEN
        IF v_old_streak < 7 AND v_new_streak >= 7 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 7;
        ELSIF v_old_streak < 30 AND v_new_streak >= 30 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 30;
        ELSIF v_old_streak < 182 AND v_new_streak >= 182 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 182;
        ELSIF v_old_streak < 365 AND v_new_streak >= 365 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 365;
        END IF;
        
        -- Calcular bônus e pontos do período se milestone atingido
        IF v_milestone_reached THEN
            -- Calcular bônus usando função existente
            v_bonus_points := calculate_streak_bonus(p_user_id, v_completed_milestone);
            
            -- Calcular pontos do período (últimos X dias)
            SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
            FROM points_history 
            WHERE user_id = p_user_id 
            AND created_at >= CURRENT_DATE - INTERVAL '1 day' * v_completed_milestone;
            
            -- CREDITAR OS PONTOS BÔNUS NA CONTA DO USUÁRIO
            IF v_bonus_points > 0 THEN
                INSERT INTO points_history (user_id, points_earned, action_type, description, created_at)
                VALUES (
                    p_user_id,
                    v_bonus_points,
                    'streak_bonus',
                    'Bônus de ' || v_completed_milestone || ' dias de streak (' || v_bonus_points || ' pontos)',
                    NOW()
                );
                
                -- ATUALIZAR PONTOS TOTAIS E NÍVEL DO USUÁRIO
                PERFORM update_user_points_and_level(p_user_id);
                
                RAISE NOTICE 'Bônus creditado e pontos atualizados: User % - % pontos por milestone de % dias', 
                    p_user_id, v_bonus_points, v_completed_milestone;
            END IF;
        END IF;
    END IF;
    
    -- Log para debug
    RAISE NOTICE 'Streak com dados: User % - Streak %→% (Milestone: %, Bônus: %)', 
        p_user_id, v_old_streak, v_new_streak, v_milestone_reached, v_bonus_points;
    
    -- Retornar dados JSON para o frontend
    RETURN json_build_object(
        'current_streak', COALESCE(v_new_streak, 0),
        'milestone_reached', v_milestone_reached,
        'bonus_points', COALESCE(v_bonus_points, 0),
        'completed_milestone', COALESCE(v_completed_milestone, 0),
        'points_period', COALESCE(v_points_period, 0),
        'next_milestone', COALESCE(v_next_milestone, 7),
        'old_streak', COALESCE(v_old_streak, 0)
    );
END;
$function$;

-- Mensagem de sucesso simples
SELECT 'Função update_user_streak_with_data atualizada com sucesso!' as status;
