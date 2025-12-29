-- ============================================================================
-- FUNÇÃO: check_and_award_badges
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_and_award_badges(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_badge RECORD;
    v_user_stats RECORD;
    v_badges_awarded TEXT[] := '{}';
    v_condition_met BOOLEAN;
    v_result JSON;
BEGIN
    -- Obter estatísticas do usuário COM CÁLCULOS REAIS
    SELECT 
        -- Posts criados
        (SELECT COUNT(*) FROM public.posts WHERE user_id = p_user_id) as posts_count,
        
        -- Reações dadas
        (SELECT COUNT(*) FROM public.reactions WHERE user_id = p_user_id) as reactions_given,
        
        -- Reações recebidas
        (SELECT COUNT(*) FROM public.reactions r 
         JOIN public.posts p ON r.post_id = p.id 
         WHERE p.user_id = p_user_id) as reactions_received,
        
        -- Comentários escritos
        (SELECT COUNT(*) FROM public.comments WHERE user_id = p_user_id) as comments_written,
        
        -- Holofotes dados (pessoas destacadas)
        (SELECT COUNT(DISTINCT mentioned_user_id) FROM public.posts 
         WHERE user_id = p_user_id AND mentioned_user_id IS NOT NULL) as unique_people_highlighted,
        
        -- Holofotes recebidos
        (SELECT COUNT(*) FROM public.posts WHERE mentioned_user_id = p_user_id) as holofotes_received,
        
        -- STREAK REAL (CORRIGIDO)
        calculate_user_streak(p_user_id) as streak_days,
        
        -- Total de interações recebidas
        (SELECT COUNT(*) FROM public.reactions r 
         JOIN public.posts p ON r.post_id = p.id 
         WHERE p.user_id = p_user_id) + 
        (SELECT COUNT(*) FROM public.comments c 
         JOIN public.posts p ON c.post_id = p.id 
         WHERE p.user_id = p_user_id) as interactions_received,
         
        -- Total de interações em posts
        (SELECT COALESCE(SUM(
            (SELECT COUNT(*) FROM public.reactions WHERE post_id = posts.id) +
            (SELECT COUNT(*) FROM public.comments WHERE post_id = posts.id)
        ), 0) FROM public.posts WHERE user_id = p_user_id) as total_post_interactions,
        
        -- REFERRALS REAL (CORRIGIDO)
        count_user_referrals(p_user_id) as referrals_count
        
    INTO v_user_stats;
    
    -- Log das estatísticas para debug
    RAISE NOTICE 'Estatísticas do usuário %: posts=%, reações_dadas=%, reações_recebidas=%, comentários=%, holofotes_dados=%, holofotes_recebidos=%, streak=%, referrals=%, interações_recebidas=%', 
        p_user_id, v_user_stats.posts_count, v_user_stats.reactions_given, v_user_stats.reactions_received, 
        v_user_stats.comments_written, v_user_stats.unique_people_highlighted, v_user_stats.holofotes_received,
        v_user_stats.streak_days, v_user_stats.referrals_count, v_user_stats.interactions_received;
    
    -- Verificar cada badge (resto da função permanece igual)
    FOR v_badge IN 
        SELECT * FROM public.badges 
        WHERE is_active = true 
        AND id NOT IN (SELECT badge_id FROM public.user_badges WHERE user_id = p_user_id)
    LOOP
        v_condition_met := false;
        
        -- Verificar condição baseada no tipo
        CASE v_badge.condition_type
            WHEN 'posts_count' THEN
                v_condition_met := v_user_stats.posts_count >= v_badge.condition_value;
            WHEN 'reactions_given' THEN
                v_condition_met := v_user_stats.reactions_given >= v_badge.condition_value;
            WHEN 'reactions_received' THEN
                v_condition_met := v_user_stats.reactions_received >= v_badge.condition_value;
            WHEN 'comments_written' THEN
                v_condition_met := v_user_stats.comments_written >= v_badge.condition_value;
            WHEN 'unique_people_highlighted' THEN
                v_condition_met := v_user_stats.unique_people_highlighted >= v_badge.condition_value;
            WHEN 'holofotes_given' THEN
                v_condition_met := v_user_stats.unique_people_highlighted >= v_badge.condition_value;
            WHEN 'interactions_received' THEN
                v_condition_met := v_user_stats.interactions_received >= v_badge.condition_value;
            WHEN 'streak_days' THEN
                v_condition_met := v_user_stats.streak_days >= v_badge.condition_value;
            WHEN 'total_post_interactions' THEN
                v_condition_met := v_user_stats.total_post_interactions >= v_badge.condition_value;
            WHEN 'referrals_count' THEN
                v_condition_met := v_user_stats.referrals_count >= v_badge.condition_value;
            WHEN 'early_adopter' THEN
                v_condition_met := (SELECT COUNT(*) FROM auth.users WHERE created_at < (SELECT created_at FROM auth.users WHERE id = p_user_id)) <= 100;
        END CASE;
        
        -- Se condição foi atendida, conceder badge
        IF v_condition_met THEN
            INSERT INTO public.user_badges (user_id, badge_id, earned_at)
            VALUES (p_user_id, v_badge.id, NOW())
            ON CONFLICT (user_id, badge_id) DO NOTHING;
            
            v_badges_awarded := array_append(v_badges_awarded, v_badge.name);
        END IF;
    END LOOP;
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'badges_awarded', v_badges_awarded,
        'user_stats', row_to_json(v_user_stats)
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$

