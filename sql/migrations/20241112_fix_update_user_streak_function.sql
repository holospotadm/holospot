-- ============================================================================
-- FIX: Corrigir função update_user_streak - erro "(0,0,)"
-- ============================================================================
-- Data: 2025-11-12
-- Problema: Linha 5255 tenta atribuir RECORD a INTEGER
-- Erro: v_new_streak := calculate_user_streak(p_user_id)
-- Causa: calculate_user_streak() retorna TABLE (3 colunas), não INTEGER
-- Solução: Usar SELECT INTO para extrair apenas current_streak
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_new_streak INTEGER;
    v_old_streak INTEGER;
    v_old_milestone INTEGER;
    v_next_milestone INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
    v_milestone_value INTEGER;
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
    
    -- Calcular novo streak (CORRIGIDO: usar SELECT INTO em vez de atribuição direta)
    SELECT current_streak INTO v_new_streak
    FROM calculate_user_streak(p_user_id);
    
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
    
    -- Atualizar ou inserir dados na tabela (usando timezone do usuário)
    INSERT INTO user_streaks (user_id, current_streak, next_milestone, last_activity_date, updated_at)
    VALUES (p_user_id, v_new_streak, v_next_milestone, v_current_date, NOW())
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
$function$;

-- ============================================================================
-- REABILITAR TRIGGER
-- ============================================================================
-- Agora que a função está corrigida, reabilitar o trigger
ALTER TABLE public.feedbacks ENABLE TRIGGER update_streak_after_feedback;

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Para testar:
-- 1. Dar um feedback
-- 2. Verificar se salva sem erro
-- 3. Verificar se o streak aumenta corretamente
-- ============================================================================
