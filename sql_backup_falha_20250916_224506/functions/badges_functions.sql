-- ============================================================================
-- FUNÇÕES DE BADGES - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de funções: 5
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- FUNÇÃO: auto_check_badges_after_action
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_check_badges_after_action()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    affected_user_id UUID;
    post_owner_id UUID;
    result_text TEXT;
BEGIN
    -- Determinar qual usuário foi afetado baseado na tabela e operação
    IF TG_TABLE_NAME = 'posts' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar usuário mencionado se houver
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'comments' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar dono do post
            SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
            IF post_owner_id IS NOT NULL AND post_owner_id != NEW.user_id THEN
                SELECT check_and_grant_badges(post_owner_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'feedbacks' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.author_id;
            -- Também verificar usuário mencionado
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'user_points' THEN
        IF TG_OP = 'UPDATE' THEN
            affected_user_id := NEW.user_id;
        END IF;
    END IF;
    
    -- Verificar badges para o usuário principal afetado
    IF affected_user_id IS NOT NULL THEN
        SELECT check_and_grant_badges(affected_user_id) INTO result_text;
        IF result_text != 'Nenhum badge novo concedido' THEN
            RAISE NOTICE 'Auto-check badges: %', result_text;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$
;

-- FUNÇÃO: auto_check_badges_with_bonus_after_action
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_check_badges_with_bonus_after_action()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    affected_user_id UUID;
    post_owner_id UUID;
    result_text TEXT;
BEGIN
    -- Determinar qual usuário foi afetado baseado na tabela e operação
    IF TG_TABLE_NAME = 'posts' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar usuário mencionado se houver
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'comments' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar dono do post
            SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
            IF post_owner_id IS NOT NULL AND post_owner_id != NEW.user_id THEN
                SELECT check_and_grant_badges_with_bonus(post_owner_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'feedbacks' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.author_id;
            -- Também verificar usuário mencionado
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'user_points' THEN
        IF TG_OP = 'UPDATE' THEN
            affected_user_id := NEW.user_id;
        END IF;
    END IF;
    
    -- Verificar badges para o usuário principal afetado
    IF affected_user_id IS NOT NULL THEN
        SELECT check_and_grant_badges_with_bonus(affected_user_id) INTO result_text;
        IF result_text != 'Nenhum badge novo concedido' THEN
            RAISE NOTICE 'Auto-check badges com bônus: %', result_text;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$
;

-- FUNÇÃO: check_and_award_badges
-- ============================================================================

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
;

-- FUNÇÃO: check_and_grant_badges
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_and_grant_badges(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    badge_record RECORD;
    current_count INTEGER;
    badges_granted INTEGER := 0;
    result_text TEXT := '';
BEGIN
    -- Buscar todos os badges que o usuário ainda não tem
    FOR badge_record IN 
        SELECT b.* 
        FROM public.badges b
        WHERE NOT EXISTS (
            SELECT 1 FROM public.user_badges ub 
            WHERE ub.user_id = p_user_id 
            AND ub.badge_id = b.id
        )
    LOOP
        current_count := 0;
        
        -- Calcular progresso atual baseado no tipo de condição
        CASE badge_record.condition_type
            WHEN 'posts_count' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id;
                
            WHEN 'reactions_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.reactions 
                WHERE user_id = p_user_id;
                
            WHEN 'comments_written' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.comments 
                WHERE user_id = p_user_id;
                
            WHEN 'feedbacks_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.feedbacks 
                WHERE mentioned_user_id = p_user_id;
                
            WHEN 'holofotes_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND mentioned_user_id IS NOT NULL;
                
            WHEN 'total_points' THEN
                SELECT COALESCE(total_points, 0) INTO current_count
                FROM public.user_points 
                WHERE user_id = p_user_id;
                
            ELSE
                current_count := 0;
        END CASE;
        
        -- Se atingiu a condição, conceder o badge
        IF current_count >= badge_record.condition_value THEN
            INSERT INTO public.user_badges (user_id, badge_id, earned_at)
            VALUES (p_user_id, badge_record.id, NOW())
            ON CONFLICT (user_id, badge_id) DO NOTHING;
            
            -- Verificar se foi realmente inserido (não era duplicata)
            IF FOUND THEN
                badges_granted := badges_granted + 1;
                result_text := result_text || 'Badge "' || badge_record.name || '" concedido! ';
                
                RAISE NOTICE 'Badge % concedido para usuário %', badge_record.name, p_user_id;
            END IF;
        END IF;
    END LOOP;
    
    IF badges_granted > 0 THEN
        RETURN 'Concedidos ' || badges_granted || ' badges: ' || result_text;
    ELSE
        RETURN 'Nenhum badge novo concedido';
    END IF;
END;
$function$
;

-- FUNÇÃO: check_and_grant_badges_with_bonus
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_and_grant_badges_with_bonus(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    badge_record RECORD;
    current_count INTEGER;
    badges_granted INTEGER := 0;
    total_bonus_points INTEGER := 0;
    bonus_points INTEGER;
    result_text TEXT := '';
BEGIN
    -- Buscar todos os badges que o usuário ainda não tem
    FOR badge_record IN 
        SELECT b.* 
        FROM public.badges b
        WHERE NOT EXISTS (
            SELECT 1 FROM public.user_badges ub 
            WHERE ub.user_id = p_user_id 
            AND ub.badge_id = b.id
        )
    LOOP
        current_count := 0;
        
        -- Calcular progresso atual baseado no tipo de condição
        CASE badge_record.condition_type
            WHEN 'posts_count' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id;
                
            WHEN 'reactions_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.reactions 
                WHERE user_id = p_user_id;
                
            WHEN 'comments_written' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.comments 
                WHERE user_id = p_user_id;
                
            WHEN 'feedbacks_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.feedbacks 
                WHERE mentioned_user_id = p_user_id;
                
            WHEN 'holofotes_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND mentioned_user_id IS NOT NULL;
                
            WHEN 'total_points' THEN
                SELECT COALESCE(total_points, 0) INTO current_count
                FROM public.user_points 
                WHERE user_id = p_user_id;
                
            ELSE
                current_count := 0;
        END CASE;
        
        -- Se atingiu a condição, conceder o badge
        IF current_count >= badge_record.condition_value THEN
            -- Inserir badge na tabela user_badges
            INSERT INTO public.user_badges (user_id, badge_id, earned_at)
            VALUES (p_user_id, badge_record.id, NOW())
            ON CONFLICT (user_id, badge_id) DO NOTHING;
            
            -- Verificar se foi realmente inserido (não era duplicata)
            IF FOUND THEN
                badges_granted := badges_granted + 1;
                
                -- Calcular pontos bônus baseado na raridade
                bonus_points := get_badge_bonus_points(badge_record.rarity);
                total_bonus_points := total_bonus_points + bonus_points;
                
                -- Adicionar pontos bônus ao histórico
                PERFORM add_points_secure(
                    p_user_id, 
                    bonus_points, 
                    'badge_earned', 
                    badge_record.id, 
                    'badge',
                    NULL, -- post_id
                    badge_record.rarity, -- reaction_type (usando para armazenar rarity)
                    NULL -- reaction_user_id
                );
                
                result_text := result_text || 'Badge "' || badge_record.name || '" (' || badge_record.rarity || ') = +' || bonus_points || ' pts! ';
                
                RAISE NOTICE 'Badge % (%) concedido para usuário % (+% pontos)', 
                            badge_record.name, badge_record.rarity, p_user_id, bonus_points;
            END IF;
        END IF;
    END LOOP;
    
    -- Recalcular pontos totais se houve badges concedidos
    IF badges_granted > 0 THEN
        PERFORM recalculate_user_points_secure(p_user_id);
        RETURN 'Concedidos ' || badges_granted || ' badges (+' || total_bonus_points || ' pts bônus): ' || result_text;
    ELSE
        RETURN 'Nenhum badge novo concedido';
    END IF;
END;
$function$
;

