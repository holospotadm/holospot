-- ============================================================================
-- Fix: Tratar last_activity_date NULL como primeira atividade
-- ============================================================================
-- Data: 2025-11-12
-- Problema: Função não retorna nada quando last_activity_date é NULL
-- Causa: NULL não é igual nem menor que nada, nenhum IF é ativado
-- Solução: Tratar v_current_streak IS NULL OR v_last_activity IS NULL
-- ============================================================================

DROP FUNCTION IF EXISTS public.update_user_streak_incremental(UUID);

CREATE OR REPLACE FUNCTION public.update_user_streak_incremental(p_user_id UUID)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    milestone_reached BOOLEAN,
    milestone_value INTEGER,
    bonus_points INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_user_timezone TEXT;
    v_today DATE;
    v_yesterday DATE;
    v_last_activity DATE;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_new_streak INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
    v_milestone_value INTEGER := NULL;
    v_bonus_points INTEGER := 0;
    v_next_milestone INTEGER;
BEGIN
    SELECT timezone INTO v_user_timezone FROM profiles WHERE profiles.id = p_user_id;
    IF v_user_timezone IS NULL THEN v_user_timezone := 'America/Sao_Paulo'; END IF;
    
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    
    RAISE NOTICE '🔍 Streak incremental - User: %, Hoje: %, Ontem: %', p_user_id, v_today, v_yesterday;
    
    -- FIX: Qualificar explicitamente com user_streaks.
    SELECT user_streaks.current_streak, user_streaks.longest_streak, user_streaks.last_activity_date
    INTO v_current_streak, v_longest_streak, v_last_activity
    FROM user_streaks WHERE user_streaks.user_id = p_user_id;
    
    RAISE NOTICE '📊 Streak atual: current=%, longest=%, last_activity=%', v_current_streak, v_longest_streak, v_last_activity;
    
    -- CENÁRIO 1: Primeira atividade (current_streak NULL OU last_activity NULL)
    -- FIX: Adicionar OR v_last_activity IS NULL
    IF v_current_streak IS NULL OR v_last_activity IS NULL THEN
        RAISE NOTICE '✨ Primeira atividade! Criando/atualizando streak inicial';
        
        -- Se já existe registro mas sem last_activity, fazer UPDATE
        IF v_current_streak IS NOT NULL THEN
            UPDATE user_streaks SET
                current_streak = 1,
                longest_streak = GREATEST(COALESCE(user_streaks.longest_streak, 0), 1),
                last_activity_date = v_today,
                next_milestone = 7,
                updated_at = NOW()
            WHERE user_streaks.user_id = p_user_id;
            RETURN QUERY SELECT 1, GREATEST(COALESCE(v_longest_streak, 0), 1), v_today, FALSE, NULL::INTEGER, 0;
        ELSE
            -- Não existe registro, fazer INSERT
            INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date, next_milestone, updated_at)
            VALUES (p_user_id, 1, 1, v_today, 7, NOW());
            RETURN QUERY SELECT 1, 1, v_today, FALSE, NULL::INTEGER, 0;
        END IF;
        RETURN;
    END IF;
    
    -- CENÁRIO 2: Mesmo dia
    IF v_last_activity = v_today THEN
        RAISE NOTICE '📅 Atividade no mesmo dia - Streak não muda';
        RETURN QUERY SELECT v_current_streak, v_longest_streak, v_last_activity, FALSE, NULL::INTEGER, 0;
        RETURN;
    END IF;
    
    -- CENÁRIO 3: Consecutivo
    IF v_last_activity = v_yesterday THEN
        v_new_streak := v_current_streak + 1;
        v_longest_streak := GREATEST(v_longest_streak, v_new_streak);
        RAISE NOTICE '🔥 Atividade consecutiva! Streak: % → %', v_current_streak, v_new_streak;
        
        IF v_new_streak = 7 AND v_current_streak < 7 THEN
            v_milestone_reached := TRUE; v_milestone_value := 7; v_next_milestone := 30;
        ELSIF v_new_streak = 30 AND v_current_streak < 30 THEN
            v_milestone_reached := TRUE; v_milestone_value := 30; v_next_milestone := 182;
        ELSIF v_new_streak = 182 AND v_current_streak < 182 THEN
            v_milestone_reached := TRUE; v_milestone_value := 182; v_next_milestone := 365;
        ELSIF v_new_streak = 365 AND v_current_streak < 365 THEN
            v_milestone_reached := TRUE; v_milestone_value := 365; v_next_milestone := 365;
        ELSE
            CASE 
                WHEN v_new_streak >= 365 THEN v_next_milestone := 365;
                WHEN v_new_streak >= 182 THEN v_next_milestone := 365;
                WHEN v_new_streak >= 30 THEN v_next_milestone := 182;
                WHEN v_new_streak >= 7 THEN v_next_milestone := 30;
                ELSE v_next_milestone := 7;
            END CASE;
        END IF;
        
        UPDATE user_streaks SET
            current_streak = v_new_streak,
            longest_streak = v_longest_streak,
            last_activity_date = v_today,
            next_milestone = v_next_milestone,
            updated_at = NOW()
        WHERE user_streaks.user_id = p_user_id;
        
        IF v_milestone_reached THEN PERFORM apply_streak_bonus_retroactive(p_user_id); END IF;
        
        RETURN QUERY SELECT v_new_streak, v_longest_streak, v_today, v_milestone_reached, v_milestone_value, v_bonus_points;
        RETURN;
    END IF;
    
    -- CENÁRIO 4: Streak quebrado
    IF v_last_activity < v_yesterday THEN
        RAISE NOTICE '💔 Streak quebrado! Última atividade: %, Recomeçando do zero', v_last_activity;
        UPDATE user_streaks SET 
            current_streak = 1, 
            last_activity_date = v_today, 
            next_milestone = 7, 
            updated_at = NOW()
        WHERE user_streaks.user_id = p_user_id;
        RETURN QUERY SELECT 1, v_longest_streak, v_today, FALSE, NULL::INTEGER, 0;
        RETURN;
    END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.update_user_streak_incremental(UUID) TO authenticated;

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- SELECT * FROM update_user_streak_incremental('SEU-USER-ID');
-- Deve retornar 1 linha com streak = 1
-- ============================================================================
