-- ============================================================================
-- NOVAS FUNÇÕES DE STREAK - LÓGICA INCREMENTAL
-- ============================================================================
-- Adicionar estas funções ao ALL_FUNCTIONS.sql após a função update_user_streak
-- ============================================================================

-- FUNÇÃO: update_user_streak_incremental (NOVA - Lógica incremental)
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
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone
    FROM profiles 
    WHERE id = p_user_id;
    
    -- Default timezone
    IF v_user_timezone IS NULL THEN
        v_user_timezone := 'America/Sao_Paulo';
    END IF;
    
    -- Calcular datas no timezone do usuário
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    
    RAISE NOTICE '🔍 Streak incremental - User: %, Hoje: %, Ontem: %', p_user_id, v_today, v_yesterday;
    
    -- Buscar streak atual (se existir)
    SELECT 
        current_streak, 
        longest_streak, 
        last_activity_date
    INTO 
        v_current_streak, 
        v_longest_streak, 
        v_last_activity
    FROM user_streaks
    WHERE user_id = p_user_id;
    
    RAISE NOTICE '📊 Streak atual: current=%, longest=%, last_activity=%', v_current_streak, v_longest_streak, v_last_activity;
    
    -- CENÁRIO 1: Primeira atividade (usuário novo)
    IF v_current_streak IS NULL THEN
        RAISE NOTICE '✨ Primeira atividade! Criando streak inicial';
        
        INSERT INTO user_streaks (
            user_id,
            current_streak,
            longest_streak,
            last_activity_date,
            next_milestone,
            updated_at
        ) VALUES (
            p_user_id,
            1,
            1,
            v_today,
            7,
            NOW()
        );
        
        RETURN QUERY SELECT 1, 1, v_today, FALSE, NULL::INTEGER, 0;
        RETURN;
    END IF;
    
    -- CENÁRIO 2: Atividade no MESMO DIA (não muda streak)
    IF v_last_activity = v_today THEN
        RAISE NOTICE '📅 Atividade no mesmo dia - Streak não muda';
        
        RETURN QUERY SELECT 
            v_current_streak, 
            v_longest_streak, 
            v_last_activity, 
            FALSE, 
            NULL::INTEGER, 
            0;
        RETURN;
    END IF;
    
    -- CENÁRIO 3: Atividade CONSECUTIVA (ontem foi o último dia)
    IF v_last_activity = v_yesterday THEN
        v_new_streak := v_current_streak + 1;
        v_longest_streak := GREATEST(v_longest_streak, v_new_streak);
        
        RAISE NOTICE '🔥 Atividade consecutiva! Streak: % → %', v_current_streak, v_new_streak;
        
        -- Verificar milestone
        IF v_new_streak = 7 AND v_current_streak < 7 THEN
            v_milestone_reached := TRUE;
            v_milestone_value := 7;
            v_next_milestone := 30;
            RAISE NOTICE '🎉 Milestone atingido: 7 dias!';
        ELSIF v_new_streak = 30 AND v_current_streak < 30 THEN
            v_milestone_reached := TRUE;
            v_milestone_value := 30;
            v_next_milestone := 182;
            RAISE NOTICE '🎉 Milestone atingido: 30 dias!';
        ELSIF v_new_streak = 182 AND v_current_streak < 182 THEN
            v_milestone_reached := TRUE;
            v_milestone_value := 182;
            v_next_milestone := 365;
            RAISE NOTICE '🎉 Milestone atingido: 182 dias!';
        ELSIF v_new_streak = 365 AND v_current_streak < 365 THEN
            v_milestone_reached := TRUE;
            v_milestone_value := 365;
            v_next_milestone := 365;
            RAISE NOTICE '🎉 Milestone atingido: 365 dias!';
        ELSE
            -- Determinar próximo milestone
            CASE 
                WHEN v_new_streak >= 365 THEN v_next_milestone := 365;
                WHEN v_new_streak >= 182 THEN v_next_milestone := 365;
                WHEN v_new_streak >= 30 THEN v_next_milestone := 182;
                WHEN v_new_streak >= 7 THEN v_next_milestone := 30;
                ELSE v_next_milestone := 7;
            END CASE;
        END IF;
        
        -- Atualizar streak
        UPDATE user_streaks SET
            current_streak = v_new_streak,
            longest_streak = v_longest_streak,
            last_activity_date = v_today,
            next_milestone = v_next_milestone,
            updated_at = NOW()
        WHERE user_id = p_user_id;
        
        -- Se atingiu milestone, aplicar bônus
        IF v_milestone_reached THEN
            PERFORM apply_streak_bonus_retroactive(p_user_id);
        END IF;
        
        RETURN QUERY SELECT 
            v_new_streak, 
            v_longest_streak, 
            v_today, 
            v_milestone_reached, 
            v_milestone_value, 
            v_bonus_points;
        RETURN;
    END IF;
    
    -- CENÁRIO 4: Streak QUEBRADO (pulou dias)
    IF v_last_activity < v_yesterday THEN
        RAISE NOTICE '💔 Streak quebrado! Última atividade: %, Recomeçando do zero', v_last_activity;
        
        v_new_streak := 1;
        
        UPDATE user_streaks SET
            current_streak = 1,
            last_activity_date = v_today,
            next_milestone = 7,
            updated_at = NOW()
        WHERE user_id = p_user_id;
        
        RETURN QUERY SELECT 
            1, 
            v_longest_streak, 
            v_today, 
            FALSE, 
            NULL::INTEGER, 
            0;
        RETURN;
    END IF;
END;
$function$;


-- FUNÇÃO: update_user_streak (ATUALIZADA - Usa lógica incremental)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_result RECORD;
BEGIN
    -- Usar nova lógica incremental
    SELECT * INTO v_result
    FROM update_user_streak_incremental(p_user_id);
    
    -- Log para debug
    RAISE NOTICE 'Streak atualizado (incremental): User % - Streak: %, Milestone: %', 
        p_user_id, v_result.current_streak, v_result.milestone_reached;
END;
$function$;


-- FUNÇÃO: update_user_streak_with_data (ATUALIZADA - Wrapper para incremental)
-- ============================================================================

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
AS $function$
DECLARE
    v_result RECORD;
BEGIN
    -- Chamar nova função incremental
    SELECT * INTO v_result
    FROM update_user_streak_incremental(p_user_id);
    
    -- Retornar no formato esperado pelo frontend
    RETURN QUERY SELECT 
        v_result.current_streak,
        v_result.longest_streak,
        v_result.last_activity_date,
        v_result.milestone_reached,
        v_result.bonus_points;
END;
$function$;


-- FUNÇÃO: recalculate_user_streak_from_scratch (NOVA - Para casos especiais)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_streak_from_scratch(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
    -- Buscar timezone do usuário
    SELECT timezone INTO v_user_timezone 
    FROM public.profiles 
    WHERE id = p_user_id;
    
    IF v_user_timezone IS NULL THEN
        v_user_timezone := 'America/Sao_Paulo';
    END IF;
    
    v_today := (NOW() AT TIME ZONE v_user_timezone)::DATE;
    v_yesterday := v_today - INTERVAL '1 day';
    v_check_date := v_today;
    
    -- Loop para verificar atividades consecutivas
    FOR i IN 0..365 LOOP
        v_has_activity := FALSE;
        
        -- Contar atividades
        SELECT COUNT(*) INTO v_posts_count
        FROM public.posts 
        WHERE user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_comments_count
        FROM public.comments 
        WHERE user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_reactions_count
        FROM public.reactions 
        WHERE user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        SELECT COUNT(*) INTO v_feedbacks_count
        FROM public.feedbacks 
        WHERE mentioned_user_id = p_user_id
        AND (created_at AT TIME ZONE v_user_timezone)::DATE = v_check_date;
        
        IF v_posts_count > 0 OR v_comments_count > 0 OR v_reactions_count > 0 OR v_feedbacks_count > 0 THEN
            v_has_activity := TRUE;
            v_last_activity := v_check_date;
        END IF;
        
        IF v_has_activity THEN
            v_streak := v_streak + 1;
            IF v_streak > v_max_streak THEN
                v_max_streak := v_streak;
            END IF;
        ELSE
            IF v_check_date < v_yesterday THEN
                EXIT;
            END IF;
            IF v_check_date = v_today OR v_check_date = v_yesterday THEN
                v_streak := 0;
            END IF;
        END IF;
        
        v_check_date := v_check_date - INTERVAL '1 day';
    END LOOP;
    
    -- Atualizar user_streaks com resultado calculado
    INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date, next_milestone, updated_at)
    VALUES (p_user_id, v_streak, v_max_streak, v_last_activity, 
            CASE WHEN v_streak >= 365 THEN 365 WHEN v_streak >= 182 THEN 365 WHEN v_streak >= 30 THEN 182 WHEN v_streak >= 7 THEN 30 ELSE 7 END,
            NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        current_streak = EXCLUDED.current_streak,
        longest_streak = EXCLUDED.longest_streak,
        last_activity_date = EXCLUDED.last_activity_date,
        next_milestone = EXCLUDED.next_milestone,
        updated_at = EXCLUDED.updated_at;
    
    RAISE NOTICE '🔄 Streak recalculado do zero: User % - Streak: %', p_user_id, v_streak;
END;
$function$;
