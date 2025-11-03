-- Migration: Corrigir creditação de bônus de streak
-- Data: 2024-11-02
-- Descrição: Adicionar logs detalhados e garantir que bônus seja creditado corretamente

-- ATUALIZAR FUNÇÃO calculate_streak_bonus
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
    
    -- Calcular pontos dos últimos X dias (EXCLUINDO todos os tipos de bônus)
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction'); -- Excluir todos os bônus
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE 'Cálculo de bônus: User % - Milestone % dias - Pontos período: % - Bônus: %', 
        p_user_id, p_milestone, v_points_period, v_bonus;
    
    RETURN v_bonus;
END;
$function$;

-- ATUALIZAR FUNÇÃO update_user_streak_with_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_old_streak INTEGER;
    v_new_streak INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
    v_bonus_points INTEGER := 0;
    v_completed_milestone INTEGER;
    v_points_period INTEGER;
    v_next_milestone INTEGER;
    v_user_timezone TEXT;
    v_current_date DATE;
BEGIN
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone
    FROM profiles 
    WHERE id = p_user_id;
    
    -- Se não encontrar timezone, usar padrão do Brasil
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
            RAISE NOTICE '🎯 MILESTONE ATINGIDO! User % - Milestone: % dias', p_user_id, v_completed_milestone;
            
            -- Calcular pontos do período (últimos X dias) ANTES do bônus
            SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
            FROM points_history 
            WHERE user_id = p_user_id 
            AND created_at >= CURRENT_DATE - INTERVAL '1 day' * v_completed_milestone
            AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction');
            
            RAISE NOTICE '📊 Pontos do período (% dias): %', v_completed_milestone, v_points_period;
            
            -- Calcular bônus usando função existente
            v_bonus_points := calculate_streak_bonus(p_user_id, v_completed_milestone);
            
            RAISE NOTICE '💰 Bônus calculado: % pontos (20%% de %)', v_bonus_points, v_points_period;
            
            -- CREDITAR OS PONTOS BÔNUS NA CONTA DO USUÁRIO (mesmo se for 0)
            IF v_bonus_points >= 0 THEN
                -- Inserir registro de bônus
                INSERT INTO points_history (user_id, points_earned, action_type, description, created_at)
                VALUES (
                    p_user_id,
                    v_bonus_points,
                    'streak_bonus',
                    'Bônus de ' || v_completed_milestone || ' dias de streak - ' || v_bonus_points || ' pontos (20% de ' || v_points_period || ' pontos do período)',
                    NOW()
                );
                
                RAISE NOTICE '✅ Bônus inserido no points_history: % pontos', v_bonus_points;
                
                -- ATUALIZAR PONTOS TOTAIS E NÍVEL DO USUÁRIO
                PERFORM update_user_points_and_level(p_user_id);
                
                RAISE NOTICE '✅ Pontos totais e nível atualizados para user %', p_user_id;
                
                RAISE NOTICE '🎉 BÔNUS CREDITADO COM SUCESSO: User % - % pontos por milestone de % dias (período: % pontos)', 
                    p_user_id, v_bonus_points, v_completed_milestone, v_points_period;
            ELSE
                RAISE WARNING '⚠️ Bônus calculado é negativo ou inválido: %', v_bonus_points;
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
