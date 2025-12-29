-- ============================================================================
-- FUNÇÃO: get_user_gamification_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_gamification_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    result JSON;
    user_total_points INTEGER;
    current_level_data JSON;
    next_level_data JSON;
    progress_percentage INTEGER;
BEGIN
    -- Calcular total de pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO user_total_points
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Buscar level atual
    SELECT to_json(l.*) INTO current_level_data
    FROM public.levels l
    WHERE user_total_points >= l.min_points 
    AND user_total_points <= l.max_points
    LIMIT 1;
    
    -- Buscar próximo level
    SELECT to_json(l.*) INTO next_level_data
    FROM public.levels l
    WHERE l.min_points > user_total_points
    ORDER BY l.min_points ASC
    LIMIT 1;
    
    -- Calcular progresso
    IF current_level_data IS NOT NULL AND next_level_data IS NOT NULL THEN
        progress_percentage := CAST(
            ((user_total_points - (current_level_data->>'min_points')::INTEGER) * 100.0) / 
            ((next_level_data->>'min_points')::INTEGER - (current_level_data->>'min_points')::INTEGER)
        AS INTEGER);
    ELSE
        progress_percentage := 100;
    END IF;
    
    -- Montar resultado
    SELECT json_build_object(
        'total_points', user_total_points,
        'current_level', current_level_data,
        'next_level', next_level_data,
        'progress', GREATEST(0, LEAST(100, progress_percentage)),
        'ranking', (
            SELECT json_build_object(
                'position', (
                    SELECT COUNT(*) + 1 
                    FROM (
                        SELECT user_id, SUM(points_earned) as total
                        FROM public.points_history 
                        GROUP BY user_id
                        HAVING SUM(points_earned) > user_total_points
                    ) ranked_users
                ),
                'total_users', (
                    SELECT COUNT(DISTINCT user_id) 
                    FROM public.points_history
                )
            )
        ),
        'stats', (
            SELECT json_build_object(
                'posts_created', COALESCE(SUM(CASE WHEN action_type = 'post_created' THEN 1 ELSE 0 END), 0),
                'comments_given', COALESCE(SUM(CASE WHEN action_type = 'comment_given' THEN 1 ELSE 0 END), 0),
                'reactions_given', COALESCE(SUM(CASE WHEN action_type = 'reaction_given' THEN 1 ELSE 0 END), 0),
                'feedbacks_given', COALESCE(SUM(CASE WHEN action_type = 'feedback_given' THEN 1 ELSE 0 END), 0),
                'feedbacks_received', COALESCE(SUM(CASE WHEN action_type = 'feedback_received' THEN 1 ELSE 0 END), 0),
                'streak_days', COALESCE((
                    SELECT current_streak 
                    FROM public.user_streaks 
                    WHERE user_id = p_user_id
                ), 0)
            )
            FROM public.points_history 
            WHERE user_id = p_user_id
        ),
        'badges', (
            SELECT COALESCE(json_agg(
                json_build_object(
                    'id', b.id,
                    'name', b.name,
                    'description', b.description,
                    'icon', b.icon,
                    'rarity', b.rarity,
                    'earned_at', ub.earned_at
                )
            ), '[]'::json)
            FROM public.user_badges ub
            JOIN public.badges b ON ub.badge_id = b.id
            WHERE ub.user_id = p_user_id
        ),
        'recent_activity', (
            WITH recent_activities AS (
                SELECT 
                    action_type,
                    CASE 
                        WHEN action_type = 'post_created' THEN 10
                        WHEN action_type = 'holofote_given' THEN 20
                        WHEN action_type = 'holofote_received' THEN 15
                        WHEN action_type = 'comment_given' THEN 7
                        WHEN action_type = 'comment_received' THEN 5
                        WHEN action_type = 'reaction_given' THEN 3
                        WHEN action_type = 'reaction_received' THEN 2
                        WHEN action_type = 'feedback_given' THEN 10
                        WHEN action_type = 'feedback_received' THEN 8
                        WHEN action_type = 'badge_earned' THEN points_earned
                        ELSE points_earned
                    END as points_earned,
                    -- INCLUIR reaction_type para badges (contém a raridade)
                    CASE 
                        WHEN action_type = 'badge_earned' THEN reaction_type
                        ELSE NULL
                    END as reaction_type,
                    created_at
                FROM public.points_history 
                WHERE user_id = p_user_id
                ORDER BY created_at DESC
                LIMIT 10
            )
            SELECT COALESCE(json_agg(
                json_build_object(
                    'action_type', action_type,
                    'points_earned', points_earned,
                    'reaction_type', reaction_type,
                    'created_at', created_at
                )
            ), '[]'::json)
            FROM recent_activities
        )
    ) INTO result;
    
    RETURN result;
END;
$function$

