-- ============================================================================
-- FUNÇÃO: recalculate_user_streak_from_scratch
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_streak_from_scratch(p_user_id uuid)
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
$function$

