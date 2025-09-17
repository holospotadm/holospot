-- ============================================================================
-- TODAS AS FUNÇÕES DO HOLOSPOT - EXTRAÇÃO RIGOROSA
-- ============================================================================
-- Data: 2025-09-17 02:21:37
-- Total esperado: 116 funções
-- Método: Extração rigorosa sem perda
-- ============================================================================

-- FUNÇÃO 1: add_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_secure(p_user_id uuid, p_points integer, p_action_type text, p_reference_id uuid, p_reference_type text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Inserir pontos no histórico
    INSERT INTO public.points_history (
        user_id, points_earned, action_type, reference_id, reference_type, 
        post_id, reaction_type, reaction_user_id, created_at
    ) VALUES (
        p_user_id, p_points, p_action_type, p_reference_id, p_reference_type,
        p_post_id, p_reaction_type, p_reaction_user_id, NOW()
    );
    
    RAISE NOTICE 'Pontos adicionados: % pts para usuário % (ação: %)', p_points, p_user_id, p_action_type;
END;
$function$
;


-- FUNÇÃO: add_points_to_user
-- ============================================================================

-- FUNÇÃO 2: add_points_to_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_action_type character varying, p_points integer, p_reference_id uuid DEFAULT NULL::uuid, p_reference_type character varying DEFAULT NULL::character varying)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_current_points INTEGER;
    v_new_total_points INTEGER;
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_level_up BOOLEAN := false;
    v_result JSON;
BEGIN
    -- Inicializar pontos do usuário se não existir
    PERFORM initialize_user_points(p_user_id);
    
    -- Obter pontos atuais
    SELECT total_points, level_id INTO v_current_points, v_old_level
    FROM public.user_points 
    WHERE user_id = p_user_id;
    
    -- Calcular novos pontos
    v_new_total_points := v_current_points + p_points;
    
    -- Calcular novo nível
    v_new_level := calculate_user_level(v_new_total_points);
    
    -- Verificar se subiu de nível
    IF v_new_level > v_old_level THEN
        v_level_up := true;
    END IF;
    
    -- Atualizar pontos do usuário
    UPDATE public.user_points 
    SET 
        total_points = v_new_total_points,
        level_id = v_new_level,
        points_to_next_level = CASE 
            WHEN v_new_level < 10 THEN 
                (SELECT points_required FROM public.levels WHERE id = v_new_level + 1) - v_new_total_points
            ELSE 0
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Registrar no histórico
    INSERT INTO public.points_history (user_id, action_type, points_earned, reference_id, reference_type)
    VALUES (p_user_id, p_action_type, p_points, p_reference_id, p_reference_type);
    
    -- Verificar badges após adicionar pontos
    PERFORM check_and_award_badges(p_user_id);
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'points_added', p_points,
        'total_points', v_new_total_points,
        'old_level', v_old_level,
        'new_level', v_new_level,
        'level_up', v_level_up
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


-- FUNÇÃO: add_points_to_user
-- ============================================================================

-- FUNÇÃO 3: add_points_to_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_action_type text, p_points integer, p_reference_id uuid, p_reference_type text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Inserir no histórico de pontos com os novos campos
    INSERT INTO public.points_history (
        user_id,
        action_type,
        points_earned,
        reference_id,
        reference_type,
        post_id,
        reaction_type,
        reaction_user_id,
        created_at
    ) VALUES (
        p_user_id,
        p_action_type,
        p_points,
        p_reference_id,
        p_reference_type,
        p_post_id,
        p_reaction_type,
        p_reaction_user_id,
        NOW()
    );

    -- Atualizar total de pontos do usuário
    INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level, updated_at)
    VALUES (p_user_id, p_points, 1, GREATEST(0, 100 - p_points), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = user_points.total_points + p_points,
        updated_at = NOW();
END;
$function$
;


-- FUNÇÃO: add_points_to_user
-- ============================================================================

-- FUNÇÃO 4: add_points_to_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_points integer, p_action_type text, p_reference_id text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Inserir pontos no histórico
    INSERT INTO public.points_history (
        user_id,
        points_earned,
        action_type,
        reference_id,
        post_id,
        reaction_type,
        reaction_user_id,
        created_at
    ) VALUES (
        p_user_id,
        p_points,
        p_action_type,
        p_reference_id::uuid,  -- Cast TEXT para UUID
        p_post_id,
        p_reaction_type,
        p_reaction_user_id,
        NOW()
    );
    
    -- Atualizar total de pontos na tabela user_points (se existir)
    BEGIN
        INSERT INTO public.user_points (user_id, total_points, updated_at)
        VALUES (p_user_id, p_points, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = user_points.total_points + p_points,
            updated_at = NOW();
    EXCEPTION
        WHEN undefined_table THEN
            -- Tabela user_points não existe, ignorar
            NULL;
    END;
        
EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro
        RAISE NOTICE 'Erro ao adicionar pontos para usuário %: %', p_user_id, SQLERRM;
        -- Não falhar, apenas continuar
END;
$function$
;


-- FUNÇÃO: apply_streak_bonus_retroactive
-- ============================================================================

-- FUNÇÃO 5: apply_streak_bonus_retroactive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
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
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE RETURN; -- Não atingiu milestone
    END CASE;
    
    -- Calcular bônus usando função corrigida (agora recebe user_id)
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RETURN;
    END IF;
    
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
$function$
;


-- FUNÇÃO: auto_check_badges_after_action
-- ============================================================================

-- FUNÇÃO 6: auto_check_badges_after_action
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

-- FUNÇÃO 7: auto_check_badges_with_bonus_after_action
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


-- FUNÇÃO: auto_group_all_notifications
-- ============================================================================

-- FUNÇÃO 8: auto_group_all_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_group_all_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    user_record RECORD;
    total_grouped INTEGER := 0;
    user_grouped INTEGER;
BEGIN
    -- Para cada usuário com notificações recentes não agrupadas
    FOR user_record IN 
        SELECT DISTINCT user_id 
        FROM public.notifications 
        WHERE created_at >= NOW() - INTERVAL '6 hours'
        AND group_key IS NULL
        AND type = 'reaction'
    LOOP
        -- Executar agrupamento para este usuário
        SELECT group_reaction_notifications(user_record.user_id, 2) INTO user_grouped;
        total_grouped := total_grouped + user_grouped;
    END LOOP;
    
    RETURN total_grouped;
END;
$function$
;


-- FUNÇÃO: auto_group_recent_notifications
-- ============================================================================

-- FUNÇÃO 9: auto_group_recent_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_group_recent_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    grouped_count INTEGER := 0;
    user_record RECORD;
    reaction_group RECORD;
BEGIN
    -- Para cada usuário com notificações de reação recentes
    FOR user_record IN 
        SELECT DISTINCT user_id 
        FROM public.notifications 
        WHERE type = 'reaction'
        AND created_at >= NOW() - INTERVAL '30 minutes'
        AND group_key IS NULL
    LOOP
        -- Verificar se tem múltiplas reações do mesmo usuário
        FOR reaction_group IN
            SELECT 
                from_user_id,
                COUNT(*) as reaction_count,
                array_agg(DISTINCT 
                    CASE 
                        WHEN message LIKE '%❤️%' THEN '❤️'
                        WHEN message LIKE '%✨%' THEN '✨'
                        WHEN message LIKE '%🙏%' THEN '🙏'
                        ELSE '👍'
                    END
                ) as emojis,
                array_agg(id) as notification_ids,
                MAX(created_at) as last_created
            FROM public.notifications 
            WHERE user_id = user_record.user_id
            AND type = 'reaction'
            AND created_at >= NOW() - INTERVAL '30 minutes'
            AND group_key IS NULL
            GROUP BY from_user_id
            HAVING COUNT(*) >= 2
        LOOP
            -- Criar notificação agrupada
            INSERT INTO public.notifications (
                user_id, from_user_id, type, message, 
                group_key, group_count, priority, created_at
            ) VALUES (
                user_record.user_id,
                reaction_group.from_user_id,
                'reaction_grouped',
                (SELECT username FROM public.profiles WHERE id = reaction_group.from_user_id) || 
                ' reagiu (' || array_to_string(reaction_group.emojis, '') || ') aos seus posts',
                'group_' || reaction_group.from_user_id::text || '_' || user_record.user_id::text,
                reaction_group.reaction_count,
                2,
                reaction_group.last_created
            );
            
            -- Marcar originais como agrupadas (não deletar, só marcar)
            UPDATE public.notifications 
            SET group_key = 'group_' || reaction_group.from_user_id::text || '_' || user_record.user_id::text
            WHERE id = ANY(reaction_group.notification_ids);
            
            grouped_count := grouped_count + 1;
        END LOOP;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$
;


-- FUNÇÃO: calculate_streak_bonus
-- ============================================================================

-- FUNÇÃO 10: calculate_streak_bonus
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_points integer, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
BEGIN
    CASE p_milestone
        WHEN 7 THEN v_multiplier := 1.2;   -- +20%
        WHEN 30 THEN v_multiplier := 1.5;  -- +50%
        WHEN 180 THEN v_multiplier := 1.8; -- +80%
        WHEN 365 THEN v_multiplier := 2.0; -- +100%
        ELSE v_multiplier := 1.0;
    END CASE;
    
    -- Bonus = Pontos × (Multiplicador - 1)
    RETURN ROUND(p_points * (v_multiplier - 1));
END;
$function$
;


-- FUNÇÃO: calculate_streak_bonus
-- ============================================================================

-- FUNÇÃO 11: calculate_streak_bonus
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_user_id uuid, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
    v_days_back INTEGER;
    v_points_period INTEGER;
    v_bonus INTEGER;
BEGIN
    -- Determinar multiplicador e período baseado no milestone
    CASE p_milestone
        WHEN 7 THEN 
            v_multiplier := 1.2;   -- +20%
            v_days_back := 7;
        WHEN 30 THEN 
            v_multiplier := 1.5;   -- +50%
            v_days_back := 30;
        WHEN 182 THEN 
            v_multiplier := 1.8;   -- +80%
            v_days_back := 182;
        WHEN 365 THEN 
            v_multiplier := 2.0;   -- +100%
            v_days_back := 365;
        ELSE 
            v_multiplier := 1.0;
            v_days_back := 0;
    END CASE;
    
    -- Se não é um milestone válido, retornar 0
    IF v_days_back = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular pontos dos últimos X dias
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type != 'streak_bonus_retroactive'; -- Excluir bônus anteriores
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE 'Cálculo de bônus: User % - Milestone % dias - Pontos período: % - Bônus: %', 
        p_user_id, p_milestone, v_points_period, v_bonus;
    
    RETURN v_bonus;
END;
$function$
;


-- FUNÇÃO: calculate_user_level
-- ============================================================================

-- FUNÇÃO 12: calculate_user_level
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_level(user_points integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_level INTEGER;
BEGIN
    SELECT id INTO user_level
    FROM public.levels
    WHERE points_required <= user_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    RETURN COALESCE(user_level, 1);
END;
$function$
;


-- FUNÇÃO: calculate_user_streak
-- ============================================================================

-- FUNÇÃO 13: calculate_user_streak
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_check_date DATE;
    v_has_activity BOOLEAN;
BEGIN
    v_check_date := v_current_date;
    
    -- Loop para contar dias consecutivos com atividade
    LOOP
        -- Verificar atividades do dia (LÓGICA CORRIGIDA CONFORME ESPECIFICAÇÃO)
        SELECT EXISTS (
            SELECT 1 FROM (
                -- Posts criados mencionando outros (@username)
                SELECT DATE(created_at) as activity_date 
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND (content ~ '@\w+' OR content IS NOT NULL)  -- Posts com menções ou qualquer post
                
                UNION ALL
                
                -- Comentários em qualquer post (incluindo próprios)
                SELECT DATE(created_at) as activity_date 
                FROM public.comments 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Reações em qualquer post
                SELECT DATE(created_at) as activity_date 
                FROM public.reactions 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Feedbacks ESCRITOS (giving feedback on any post)
                SELECT DATE(created_at) as activity_date 
                FROM public.feedbacks 
                WHERE author_id = p_user_id
            ) activities
            WHERE activity_date = v_check_date
        ) INTO v_has_activity;
        
        -- Se não houve atividade neste dia, parar o loop
        IF NOT v_has_activity THEN
            -- Se é hoje e não tem atividade, streak é 0
            IF v_check_date = v_current_date THEN
                v_streak := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Se houve atividade, incrementar streak
        v_streak := v_streak + 1;
        
        -- Ir para o dia anterior
        v_check_date := v_check_date - INTERVAL '1 day';
        
        -- Limite de segurança para evitar loop infinito (máximo 365 dias)
        IF v_streak >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_streak;
END;
$function$
;


-- FUNÇÃO: check_and_award_badges
-- ============================================================================

-- FUNÇÃO 14: check_and_award_badges
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

-- FUNÇÃO 15: check_and_grant_badges
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

-- FUNÇÃO 16: check_and_grant_badges_with_bonus
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


-- FUNÇÃO: check_notification_spam
-- ============================================================================

-- FUNÇÃO 17: check_notification_spam
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_notification_spam(p_user_id uuid, p_from_user_id uuid, p_type text, p_reference_id text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
BEGIN
    -- Obter threshold para este tipo
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Se threshold é -1, sempre permitir
    IF threshold_hours = -1 THEN
        RETURN true;
    END IF;
    
    -- Se threshold é 0, sempre permitir
    IF threshold_hours = 0 THEN
        RETURN true;
    END IF;
    
    -- Contar notificações similares no período
    SELECT COUNT(*) INTO existing_count
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL
    AND (p_reference_id IS NULL OR message LIKE '%' || p_reference_id || '%');
    
    -- Retornar se pode criar (0 = pode criar)
    RETURN existing_count = 0;
END;
$function$
;


-- FUNÇÃO: check_points_before_deletion
-- ============================================================================

-- FUNÇÃO 18: check_points_before_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_points_before_deletion()
 RETURNS TABLE(user_id uuid, points_history_count bigint, points_history_total bigint, user_points_total integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ph.user_id,
        COUNT(ph.id) as points_history_count,
        COALESCE(SUM(ph.points_earned), 0) as points_history_total,
        COALESCE(up.total_points, 0) as user_points_total
    FROM public.points_history ph
    LEFT JOIN public.user_points up ON ph.user_id = up.user_id
    WHERE ph.user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
    GROUP BY ph.user_id, up.total_points
    ORDER BY ph.user_id;
END;
$function$
;


-- FUNÇÃO: cleanup_old_notifications
-- ============================================================================

-- FUNÇÃO 19: cleanup_old_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_notifications(days_to_keep integer DEFAULT 30)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Deletar notificações antigas
    DELETE FROM public.notifications 
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$function$
;


-- FUNÇÃO: count_user_referrals
-- ============================================================================

-- FUNÇÃO 20: count_user_referrals
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_referrals(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.user_referrals
        WHERE referrer_id = p_user_id
        AND is_active = true
    );
END;
$function$
;


-- FUNÇÃO: create_notification_no_duplicates
-- ============================================================================

-- FUNÇÃO 21: create_notification_no_duplicates
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_no_duplicates(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_notification_id UUID;
    can_create BOOLEAN := false;
BEGIN
    -- Não criar para si mesmo (exceto gamificação)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter threshold
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificar se já existe notificação EXATA
    SELECT id INTO existing_notification_id
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND (
        -- Para badges/level up: verificar se já existe (nunca duplicar)
        (threshold_hours = -1 AND message = p_message) OR
        -- Para feedbacks: verificar últimas 24h
        (threshold_hours = 0 AND created_at > NOW() - INTERVAL '24 hours') OR
        -- Para outros: verificar período específico
        (threshold_hours > 0 AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL)
    )
    LIMIT 1;
    
    -- Se não existe, pode criar
    IF existing_notification_id IS NULL THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RAISE NOTICE 'Notificação criada: % de % para %', p_type, p_from_user_id, p_user_id;
        RETURN true;
    ELSE
        RAISE NOTICE 'Notificação BLOQUEADA (duplicada): % de % para %', p_type, p_from_user_id, p_user_id;
        RETURN false;
    END IF;
END;
$function$
;


-- FUNÇÃO: create_notification_smart
-- ============================================================================

-- FUNÇÃO 22: create_notification_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_smart(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    should_create BOOLEAN;
BEGIN
    -- Não criar notificação para si mesmo (exceto badges/level up)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter limite específico para este tipo
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificar se deve criar
    SELECT should_create_notification(
        p_user_id, p_from_user_id, p_type, threshold_hours
    ) INTO should_create;
    
    -- Se deve criar, inserir notificação
    IF should_create THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$function$
;


-- FUNÇÃO: create_notification_ultra_safe
-- ============================================================================

-- FUNÇÃO 23: create_notification_ultra_safe
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_ultra_safe(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
    exact_match_count INTEGER;
BEGIN
    -- Não criar para si mesmo (exceto gamificação)
    IF p_from_user_id = p_user_id AND p_type NOT IN ('badge_earned', 'level_up', 'milestone') THEN
        RETURN false;
    END IF;
    
    -- Obter threshold
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Verificação 1: Mensagem exata já existe?
    SELECT COUNT(*) INTO exact_match_count
    FROM public.notifications 
    WHERE user_id = p_user_id 
    AND from_user_id = p_from_user_id 
    AND type = p_type
    AND message = p_message
    AND created_at > NOW() - INTERVAL '24 hours'; -- Sempre verificar 24h para mensagens exatas
    
    -- Se já existe mensagem exata, não criar
    IF exact_match_count > 0 THEN
        RAISE NOTICE 'BLOQUEADO: Mensagem exata já existe - %', p_message;
        RETURN false;
    END IF;
    
    -- Verificação 2: Threshold por tipo
    IF threshold_hours = -1 THEN
        -- Badges/level up: verificar se já existe
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = p_type
        AND message = p_message;
        
        IF existing_count > 0 THEN
            RAISE NOTICE 'BLOQUEADO: Badge/Level já notificado - %', p_type;
            RETURN false;
        END IF;
    ELSIF threshold_hours = 0 THEN
        -- Feedbacks: permitir sempre (já verificou mensagem exata acima)
        NULL;
    ELSE
        -- Outros tipos: verificar período
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL;
        
        IF existing_count > 0 THEN
            RAISE NOTICE 'BLOQUEADO: Dentro do período de % horas - %', threshold_hours, p_type;
            RETURN false;
        END IF;
    END IF;
    
    -- Se passou em todas as verificações, criar
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, 
        priority, read, created_at
    ) VALUES (
        p_user_id, p_from_user_id, p_type, p_message,
        p_priority, false, NOW()
    );
    
    RAISE NOTICE 'CRIADA: Notificação % de % para %', p_type, p_from_user_id, p_user_id;
    RETURN true;
END;
$function$
;


-- FUNÇÃO: create_notification_with_strict_antispam
-- ============================================================================

-- FUNÇÃO 24: create_notification_with_strict_antispam
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification_with_strict_antispam(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    threshold_hours INTEGER;
    existing_count INTEGER;
    can_create BOOLEAN := false;
BEGIN
    -- Não criar notificação para si mesmo
    IF p_from_user_id = p_user_id THEN
        RETURN false;
    END IF;
    
    -- Obter threshold específico
    SELECT get_notification_threshold(p_type) INTO threshold_hours;
    
    -- Se threshold é -1, sempre criar (badges, level up)
    IF threshold_hours = -1 THEN
        can_create := true;
    -- Se threshold é 0, sempre criar (feedbacks)
    ELSIF threshold_hours = 0 THEN
        can_create := true;
    ELSE
        -- Verificar se já existe notificação similar no período
        SELECT COUNT(*) INTO existing_count
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (threshold_hours || ' hours')::INTERVAL;
        
        -- Só criar se não existe similar
        can_create := (existing_count = 0);
    END IF;
    
    -- Se pode criar, inserir
    IF can_create THEN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RETURN true;
    ELSE
        -- Log que foi bloqueada
        RAISE NOTICE 'Notificação bloqueada por anti-spam: % de % para %', 
            p_type, p_from_user_id, p_user_id;
        RETURN false;
    END IF;
END;
$function$
;


-- FUNÇÃO: create_single_notification
-- ============================================================================

-- FUNÇÃO 25: create_single_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_single_notification(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Criar notificação simples sem agrupamento
    INSERT INTO public.notifications (
        user_id,
        from_user_id,
        type,
        message,
        read,
        created_at,
        group_key,
        group_count,
        group_data
    ) VALUES (
        p_user_id,
        p_from_user_id,
        p_type,
        p_message,
        false,
        NOW(),
        NULL,  -- Sem agrupamento para notificações simples
        1,
        NULL
    );
    
    RAISE NOTICE 'NOTIFICAÇÃO CRIADA: % para %', p_type, p_user_id;
END;
$function$
;


-- FUNÇÃO: create_test_data
-- ============================================================================

-- FUNÇÃO 26: create_test_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_test_data()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_1 UUID := '11111111-1111-1111-1111-111111111111';
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    test_post_id UUID;
    test_comment_id UUID;
    test_reaction_id UUID;
    test_feedback_id UUID;
BEGIN
    -- Limpar dados de teste anteriores
    DELETE FROM public.reactions WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.comments WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.feedbacks WHERE author_id IN (test_user_1, test_user_2) OR mentioned_user_id IN (test_user_1, test_user_2);
    DELETE FROM public.posts WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.points_history WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.user_points WHERE user_id IN (test_user_1, test_user_2);
    
    -- Criar post de teste
    INSERT INTO public.posts (id, user_id, celebrated_person_name, content, type, mentioned_user_id, created_at)
    VALUES (
        gen_random_uuid(), 
        test_user_1, 
        'Pessoa Teste', 
        'Post de teste para validação', 
        'gratitude', 
        test_user_2, 
        NOW()
    ) RETURNING id INTO test_post_id;
    
    -- Criar comentário de teste
    INSERT INTO public.comments (id, user_id, post_id, content, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_2,
        test_post_id,
        'Comentário de teste',
        NOW()
    ) RETURNING id INTO test_comment_id;
    
    -- Criar reação de teste
    INSERT INTO public.reactions (id, user_id, post_id, type, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_2,
        test_post_id,
        'like',
        NOW()
    ) RETURNING id INTO test_reaction_id;
    
    -- Criar feedback de teste
    INSERT INTO public.feedbacks (id, author_id, post_id, content, mentioned_user_id, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_1,
        test_post_id,
        'Feedback de teste',
        test_user_2,
        NOW()
    ) RETURNING id INTO test_feedback_id;
    
    RETURN 'Dados de teste criados: Post=' || test_post_id || ', Comment=' || test_comment_id || ', Reaction=' || test_reaction_id || ', Feedback=' || test_feedback_id;
END;
$function$
;


-- FUNÇÃO: delete_reaction_points_secure
-- ============================================================================

-- FUNÇÃO 27: delete_reaction_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_reaction_points_secure(p_reaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Deletar registros de pontos relacionados à reação
    DELETE FROM public.points_history 
    WHERE reference_id = p_reaction_id 
    AND reference_type = 'reaction';
    
    RAISE NOTICE 'Deletados registros de pontos para reação %', p_reaction_id;
END;
$function$
;


-- FUNÇÃO: extrair_estado_completo_banco
-- ============================================================================

-- FUNÇÃO 28: extrair_estado_completo_banco
-- ============================================================================

CREATE OR REPLACE FUNCTION public.extrair_estado_completo_banco()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    resultado TEXT := '';
    rec RECORD;
    contador INTEGER;
BEGIN
    -- Cabeçalho
    resultado := resultado || E'============================================================================\n';
    resultado := resultado || E'EXTRAÇÃO COMPLETA DO BANCO HOLOSPOT - ' || now()::text || E'\n';
    resultado := resultado || E'============================================================================\n\n';
    
    -- 1. ESTATÍSTICAS GERAIS
    resultado := resultado || E'1. ESTATÍSTICAS GERAIS\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador FROM pg_stat_user_tables WHERE schemaname = 'public';
    resultado := resultado || 'TOTAL TABELAS: ' || contador || E'\n';
    
    SELECT COUNT(*) INTO contador FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prokind = 'f';
    resultado := resultado || 'TOTAL FUNÇÕES: ' || contador || E'\n';
    
    SELECT COUNT(*) INTO contador FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND NOT t.tgisinternal;
    resultado := resultado || 'TOTAL TRIGGERS: ' || contador || E'\n';
    
    resultado := resultado || E'\n';
    
    -- 2. TODAS AS TABELAS
    resultado := resultado || E'2. TODAS AS TABELAS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT relname as nome_tabela, n_tup_ins - n_tup_del as linhas
        FROM pg_stat_user_tables 
        WHERE schemaname = 'public' 
        ORDER BY relname
    LOOP
        resultado := resultado || 'TABELA: ' || rec.nome_tabela || ' | LINHAS: ' || COALESCE(rec.linhas, 0) || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 3. TODAS AS FUNÇÕES (LISTA)
    resultado := resultado || E'3. TODAS AS FUNÇÕES (LISTA)\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname, l.lanname, 
               CASE p.prosecdef WHEN true THEN 'DEFINER' ELSE 'INVOKER' END as seguranca
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        JOIN pg_language l ON p.prolang = l.oid
        WHERE n.nspname = 'public' AND p.prokind = 'f'
        ORDER BY p.proname
    LOOP
        resultado := resultado || 'FUNÇÃO: ' || rec.proname || ' | LINGUAGEM: ' || rec.lanname || ' | SEGURANÇA: ' || rec.seguranca || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 4. TODAS AS TRIGGERS (LISTA)
    resultado := resultado || E'4. TODAS AS TRIGGERS (LISTA)\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT t.tgname, c.relname as tabela, p.proname as funcao,
               CASE t.tgenabled WHEN 'O' THEN 'ENABLED' WHEN 'D' THEN 'DISABLED' ELSE 'OTHER' END as status
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        ORDER BY c.relname, t.tgname
    LOOP
        resultado := resultado || 'TRIGGER: ' || rec.tgname || ' | TABELA: ' || rec.tabela || ' | FUNÇÃO: ' || rec.funcao || ' | STATUS: ' || rec.status || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 5. CÓDIGO FONTE DE TODAS AS FUNÇÕES
    resultado := resultado || E'5. CÓDIGO FONTE DE TODAS AS FUNÇÕES\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname, pg_get_functiondef(p.oid) as definicao
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.prokind = 'f'
        ORDER BY p.proname
    LOOP
        resultado := resultado || E'\n-- FUNÇÃO: ' || rec.proname || E'\n';
        resultado := resultado || E'-- ============================================================================\n';
        resultado := resultado || rec.definicao || E';\n\n';
    END LOOP;
    
    --

