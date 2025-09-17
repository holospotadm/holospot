-- ============================================================================
-- MIGRATION 009: CORREÇÕES CIRÚRGICAS DE UI E FUNCIONALIDADES
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: 3 correções específicas sem duplicações
-- 1. Remover descrição de benefícios da notificação de level-up
-- 2. Implementar aplicação automática de bônus de streak
-- 3. Frontend: singular/plural será corrigido separadamente
-- ============================================================================

-- CORREÇÃO 1: SIMPLIFICAR NOTIFICAÇÃO DE LEVEL-UP
-- ============================================================================
-- Remove a descrição de benefícios, mantém só o nome do nível

CREATE OR REPLACE FUNCTION public.handle_level_up_notification()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    old_level_name TEXT;
    new_level_name TEXT;
    level_info RECORD;
    message_text TEXT;
BEGIN
    -- Verificar se o nível realmente mudou
    IF OLD.level_id IS DISTINCT FROM NEW.level_id THEN
        
        -- Buscar informações do novo nível
        SELECT name, color INTO level_info
        FROM public.levels 
        WHERE id = NEW.level_id;
        
        -- Buscar nome do nível anterior (se existir)
        IF OLD.level_id IS NOT NULL THEN
            SELECT name INTO old_level_name
            FROM public.levels 
            WHERE id = OLD.level_id;
        ELSE
            old_level_name := 'Iniciante';
        END IF;
        
        -- Montar mensagem de parabéns (SEM BENEFÍCIOS)
        message_text := '🎉 Parabéns! Você subiu para o nível "' || level_info.name || '"';
        
        -- Criar notificação de nível
        PERFORM create_single_notification(
            NEW.user_id,
            NULL,  -- Notificação do sistema
            'level_up',
            message_text,
            3  -- Alta prioridade
        );
        
        RAISE NOTICE 'LEVEL UP: % subiu de % (ID:%) para % (ID:%)', 
            NEW.user_id, old_level_name, OLD.level_id, level_info.name, NEW.level_id;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- CORREÇÃO 2: IMPLEMENTAR APLICAÇÃO AUTOMÁTICA DE BÔNUS DE STREAK
-- ============================================================================
-- Criar função que aplica bônus retroativo baseado no streak atual

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_total_points INTEGER;
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
    
    -- Buscar total de pontos atual
    SELECT total_points INTO v_total_points
    FROM user_points 
    WHERE user_id = p_user_id;
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE RETURN; -- Não atingiu milestone
    END CASE;
    
    -- Calcular bônus usando função existente
    v_bonus_points := calculate_streak_bonus(v_total_points, v_milestone);
    
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

-- CORREÇÃO 3: ATUALIZAR FUNÇÃO DE STREAK PARA APLICAR BÔNUS AUTOMATICAMENTE
-- ============================================================================
-- Modificar função existente para aplicar bônus quando atingir milestones

CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_streak INTEGER;
    v_old_streak INTEGER;
    v_old_milestone INTEGER;
    v_next_milestone INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
    v_milestone_value INTEGER;
BEGIN
    -- Calcular novo streak
    v_new_streak := calculate_user_streak(p_user_id);
    
    -- Buscar dados atuais (se existirem)
    SELECT current_streak, next_milestone 
    INTO v_old_streak, v_old_milestone
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não existe registro, criar valores padrão
    IF v_old_streak IS NULL THEN
        v_old_streak := 0;
        v_old_milestone := 7;
    END IF;
    
    -- Determinar próximo milestone baseado no novo streak
    CASE 
        WHEN v_new_streak >= 365 THEN v_next_milestone := 365;  -- Máximo
        WHEN v_new_streak >= 182 THEN v_next_milestone := 365;  -- Próximo: 1 ano
        WHEN v_new_streak >= 30 THEN v_next_milestone := 182;   -- Próximo: 6 meses
        WHEN v_new_streak >= 7 THEN v_next_milestone := 30;     -- Próximo: 1 mês
        ELSE v_next_milestone := 7;                             -- Próximo: 1 semana
    END CASE;
    
    -- Verificar se atingiu um novo milestone
    IF v_new_streak > v_old_streak AND (
        (v_old_streak < 7 AND v_new_streak >= 7) OR
        (v_old_streak < 30 AND v_new_streak >= 30) OR
        (v_old_streak < 182 AND v_new_streak >= 182) OR
        (v_old_streak < 365 AND v_new_streak >= 365)
    ) THEN
        v_milestone_reached := TRUE;
        
        -- Determinar qual milestone foi atingido
        IF v_new_streak >= 365 AND v_old_streak < 365 THEN
            v_milestone_value := 365;
        ELSIF v_new_streak >= 182 AND v_old_streak < 182 THEN
            v_milestone_value := 182;
        ELSIF v_new_streak >= 30 AND v_old_streak < 30 THEN
            v_milestone_value := 30;
        ELSIF v_new_streak >= 7 AND v_old_streak < 7 THEN
            v_milestone_value := 7;
        END IF;
    END IF;
    
    -- Atualizar ou inserir dados na tabela
    INSERT INTO user_streaks (user_id, current_streak, next_milestone, last_activity_date, updated_at)
    VALUES (p_user_id, v_new_streak, v_next_milestone, CURRENT_DATE, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        current_streak = EXCLUDED.current_streak,
        next_milestone = EXCLUDED.next_milestone,
        last_activity_date = EXCLUDED.last_activity_date,
        updated_at = EXCLUDED.updated_at;
    
    -- Se atingiu milestone, aplicar bônus automaticamente
    IF v_milestone_reached THEN
        PERFORM apply_streak_bonus_retroactive(p_user_id);
    END IF;
    
    -- Log para debug
    RAISE NOTICE 'Streak atualizado: User % - Streak %→% (Milestone atingido: %)', 
        p_user_id, v_old_streak, v_new_streak, v_milestone_reached;
END;
$$;

-- APLICAR BÔNUS RETROATIVO PARA USUÁRIOS EXISTENTES
-- ============================================================================

DO $$
DECLARE
    user_record RECORD;
    total_applied INTEGER := 0;
BEGIN
    -- Aplicar bônus retroativo para todos os usuários com streak >= 7
    FOR user_record IN 
        SELECT user_id FROM user_streaks WHERE current_streak >= 7
    LOOP
        PERFORM apply_streak_bonus_retroactive(user_record.user_id);
        total_applied := total_applied + 1;
    END LOOP;
    
    RAISE NOTICE '✅ Bônus retroativo aplicado para % usuários com streak >= 7 dias', total_applied;
END $$;

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '🎉 MIGRATION 009 CONCLUÍDA - CORREÇÕES CIRÚRGICAS';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ CORREÇÃO 1: Notificação de level-up simplificada (sem benefícios)';
    RAISE NOTICE '✅ CORREÇÃO 2: Sistema de bônus de streak implementado';
    RAISE NOTICE '✅ CORREÇÃO 3: Bônus aplicado automaticamente em milestones';
    RAISE NOTICE '✅ CORREÇÃO 4: Bônus retroativo aplicado para usuários existentes';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PENDENTE: Correção frontend "1 dia" vs "X dias" (será feita no HTML)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

