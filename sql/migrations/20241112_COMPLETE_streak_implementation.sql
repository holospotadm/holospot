-- ============================================================================
-- MIGRATION COMPLETA: Nova lógica incremental de streak + Recálculo em massa
-- ============================================================================
-- Data: 2025-11-12
-- Objetivo: Implementar TUDO de uma vez
-- Execute APENAS ESTA migration se ainda não executou as outras
-- ============================================================================

-- ============================================================================
-- PARTE 1: Função incremental
-- ============================================================================

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
AS $$
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
    SELECT timezone INTO v_user_timezone FROM profiles WHERE id = p_user_id;
    IF v_user_timezone IS NULL THEN v_user_timezone := 'America/Sao_Paulo'; END IF;
    
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    
    RAISE NOTICE '🔍 Streak incremental - User: %, Hoje: %, Ontem: %', p_user_id, v_today, v_yesterday;
    
    SELECT current_streak, longest_streak, last_activity_date
    INTO v_current_streak, v_longest_streak, v_last_activity
    FROM user_streaks WHERE user_id = p_user_id;
    
    RAISE NOTICE '📊 Streak atual: current=%, longest=%, last_activity=%', v_current_streak, v_longest_streak, v_last_activity;
    
    -- CENÁRIO 1: Primeira atividade
    IF v_current_streak IS NULL THEN
        RAISE NOTICE '✨ Primeira atividade! Criando streak inicial';
        INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date, next_milestone, updated_at)
        VALUES (p_user_id, 1, 1, v_today, 7, NOW());
        RETURN QUERY SELECT 1, 1, v_today, FALSE, NULL::INTEGER, 0;
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
        WHERE user_id = p_user_id;
        
        IF v_milestone_reached THEN PERFORM apply_streak_bonus_retroactive(p_user_id); END IF;
        
        RETURN QUERY SELECT v_new_streak, v_longest_streak, v_today, v_milestone_reached, v_milestone_value, v_bonus_points;
        RETURN;
    END IF;
    
    -- CENÁRIO 4: Streak quebrado
    IF v_last_activity < v_yesterday THEN
        RAISE NOTICE '💔 Streak quebrado! Última atividade: %, Recomeçando do zero', v_last_activity;
        UPDATE user_streaks SET current_streak = 1, last_activity_date = v_today, next_milestone = 7, updated_at = NOW()
        WHERE user_id = p_user_id;
        RETURN QUERY SELECT 1, v_longest_streak, v_today, FALSE, NULL::INTEGER, 0;
        RETURN;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_user_streak_incremental(UUID) TO authenticated;

-- ============================================================================
-- PARTE 2: Atualizar funções existentes
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM update_user_streak_incremental(p_user_id);
    RAISE NOTICE 'Streak atualizado (incremental): User % - Streak: %, Milestone: %', 
        p_user_id, v_result.current_streak, v_result.milestone_reached;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id UUID)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    milestone_reached BOOLEAN,
    bonus_points INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM update_user_streak_incremental(p_user_id);
    RETURN QUERY SELECT v_result.current_streak, v_result.longest_streak, v_result.last_activity_date,
        v_result.milestone_reached, v_result.bonus_points;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_user_streak_with_data(UUID) TO authenticated;

-- ============================================================================
-- PARTE 3: Função de recálculo individual
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_streak_from_scratch(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_user_timezone TEXT;
    v_check_date DATE;
    v_today DATE;
    v_yesterday DATE;
    v_streak INTEGER := 0;
    v_max_streak INTEGER := 0;
    v_last_activity DATE;
    v_has_activity BOOLEAN;
    v_posts_count INTEGER;
    v_comments_count INTEGER;
    v_reactions_count INTEGER;
    v_feedbacks_count INTEGER;
BEGIN
    SELECT timezone INTO v_user_timezone FROM public.profiles WHERE id = p_user_id;
    IF v_user_timezone IS NULL THEN v_user_timezone := 'America/Sao_Paulo'; END IF;
    
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    v_check_date := v_today;
    
    FOR i IN 0..365 LOOP
        v_has_activity := FALSE;
        
        SELECT COUNT(*) INTO v_posts_count FROM public.posts 
        WHERE user_id = p_user_id AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_comments_count FROM public.comments 
        WHERE user_id = p_user_id AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_reactions_count FROM public.reactions 
        WHERE user_id = p_user_id AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_feedbacks_count FROM public.feedbacks 
        WHERE mentioned_user_id = p_user_id AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        IF v_posts_count > 0 OR v_comments_count > 0 OR v_reactions_count > 0 OR v_feedbacks_count > 0 THEN
            v_has_activity := TRUE;
            v_last_activity := v_check_date;
        END IF;
        
        IF v_has_activity THEN
            v_streak := v_streak + 1;
            IF v_streak > v_max_streak THEN v_max_streak := v_streak; END IF;
        ELSE
            IF v_check_date < v_yesterday THEN EXIT; END IF;
            IF v_check_date = v_today OR v_check_date = v_yesterday THEN v_streak := 0; END IF;
        END IF;
        
        v_check_date := v_check_date - INTERVAL '1 day';
    END LOOP;
    
    INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date, next_milestone, updated_at)
    VALUES (p_user_id, v_streak, v_max_streak, v_last_activity, 
            CASE WHEN v_streak >= 365 THEN 365 WHEN v_streak >= 182 THEN 365 WHEN v_streak >= 30 THEN 182 WHEN v_streak >= 7 THEN 30 ELSE 7 END,
            NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        current_streak = EXCLUDED.current_streak,
        longest_streak = EXCLUDED.longest_streak,
        last_activity_date = EXCLUDED.last_activity_date,
        next_milestone = EXCLUDED.next_milestone,
        updated_at = EXCLUDED.updated_at;
    
    RAISE NOTICE '🔄 Streak recalculado do zero: User % - Streak: %', p_user_id, v_streak;
END;
$$;

GRANT EXECUTE ON FUNCTION public.recalculate_user_streak_from_scratch(UUID) TO authenticated;

-- ============================================================================
-- PARTE 4: Função de recálculo em massa
-- ============================================================================

DROP FUNCTION IF EXISTS public.recalculate_all_users_streaks();

CREATE OR REPLACE FUNCTION public.recalculate_all_users_streaks()
RETURNS TABLE (
    user_id UUID,
    username VARCHAR(50),
    old_streak INTEGER,
    new_streak INTEGER,
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_user RECORD;
    v_old_streak INTEGER;
    v_new_streak INTEGER;
    v_total_users INTEGER := 0;
    v_processed_users INTEGER := 0;
    v_start_time TIMESTAMP;
BEGIN
    v_start_time := NOW();
    SELECT COUNT(*) INTO v_total_users FROM profiles;
    RAISE NOTICE '🔄 Iniciando recálculo de streaks para % usuários...', v_total_users;
    
    FOR v_user IN SELECT p.id, p.username FROM profiles p ORDER BY p.id LOOP
        v_processed_users := v_processed_users + 1;
        
        SELECT current_streak INTO v_old_streak FROM user_streaks WHERE user_streaks.user_id = v_user.id;
        IF v_old_streak IS NULL THEN v_old_streak := 0; END IF;
        
        BEGIN
            PERFORM recalculate_user_streak_from_scratch(v_user.id);
            SELECT current_streak INTO v_new_streak FROM user_streaks WHERE user_streaks.user_id = v_user.id;
            IF v_new_streak IS NULL THEN v_new_streak := 0; END IF;
            
            IF v_processed_users % 10 = 0 THEN
                RAISE NOTICE '📊 Progresso: %/% usuários processados (%.1f%%)', 
                    v_processed_users, v_total_users, (v_processed_users::FLOAT / v_total_users::FLOAT * 100);
            END IF;
            
            RETURN QUERY SELECT v_user.id, v_user.username::VARCHAR(50), v_old_streak, v_new_streak,
                CASE 
                    WHEN v_old_streak = v_new_streak THEN '✅ Sem mudança'
                    WHEN v_old_streak < v_new_streak THEN '📈 Aumentou'
                    ELSE '📉 Diminuiu'
                END::TEXT;
                
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erro ao processar usuário %: %', v_user.username, SQLERRM;
            RETURN QUERY SELECT v_user.id, v_user.username::VARCHAR(50), v_old_streak, 0::INTEGER,
                ('❌ Erro: ' || SQLERRM)::TEXT;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Recálculo completo! % usuários processados em %', v_processed_users, (NOW() - v_start_time);
END;
$$;

GRANT EXECUTE ON FUNCTION public.recalculate_all_users_streaks() TO authenticated;

-- ============================================================================
-- PARTE 5: Função de estatísticas
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_streak_statistics();

CREATE OR REPLACE FUNCTION public.get_streak_statistics()
RETURNS TABLE (
    total_users INTEGER,
    users_with_streak INTEGER,
    avg_streak NUMERIC,
    max_streak INTEGER,
    users_at_milestone_7 INTEGER,
    users_at_milestone_30 INTEGER,
    users_at_milestone_182 INTEGER,
    users_at_milestone_365 INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM profiles) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak > 0) as users_with_streak,
        (SELECT ROUND(AVG(current_streak), 2) FROM user_streaks WHERE current_streak > 0) as avg_streak,
        (SELECT MAX(current_streak)::INTEGER FROM user_streaks) as max_streak,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 7) as users_at_milestone_7,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 30) as users_at_milestone_30,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 182) as users_at_milestone_182,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 365) as users_at_milestone_365;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_streak_statistics() TO authenticated;

-- ============================================================================
-- INSTRUÇÕES
-- ============================================================================
-- 1. Ver estatísticas: SELECT * FROM get_streak_statistics();
-- 2. Recalcular todos: SELECT * FROM recalculate_all_users_streaks();
-- 3. Testar incremental: Dê um feedback e veja o streak aumentar!
-- ============================================================================
