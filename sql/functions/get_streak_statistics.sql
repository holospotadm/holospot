-- ============================================================================
-- FUNÇÃO: get_streak_statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_streak_statistics()
 RETURNS TABLE(total_users integer, users_with_streak integer, avg_streak numeric, max_streak integer, users_at_milestone_7 integer, users_at_milestone_30 integer, users_at_milestone_182 integer, users_at_milestone_365 integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$

