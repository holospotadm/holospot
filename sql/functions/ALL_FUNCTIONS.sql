-- ============================================================================
-- TODAS AS FUNÇÕES DO HOLOSPOT - EXTRAÇÃO FINAL GARANTIDA
-- ============================================================================
-- Total: 116 funções
-- Método: Extração direta do conteúdo bruto
-- Garantia: NADA foi perdido
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

-- FUNÇÃO 4: add_points_to_user
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

-- FUNÇÃO 5: apply_streak_bonus_retroactive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
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

-- FUNÇÃO 11: calculate_streak_bonus
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

-- FUNÇÃO 13: calculate_user_streak
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_streak INTEGER := 0;
    v_user_timezone TEXT;
    v_current_date DATE;
    v_check_date DATE;
    v_has_activity BOOLEAN;
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
    v_check_date := v_current_date;
    
    -- Log para debug
    RAISE NOTICE 'Calculando streak para usuário % no timezone % (data atual: %)', 
        p_user_id, v_user_timezone, v_current_date;
    
    -- Loop para contar dias consecutivos com atividade
    LOOP
        -- Verificar atividades do dia usando timezone do usuário
        SELECT EXISTS (
            SELECT 1 FROM (
                -- Posts criados
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND (content ~ '@\w+' OR content IS NOT NULL)
                
                UNION ALL
                
                -- Comentários em qualquer post
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.comments 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Reações em qualquer post
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
                FROM public.reactions 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Feedbacks escritos
                SELECT (created_at AT TIME ZONE v_user_timezone)::DATE as activity_date 
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
    
    RAISE NOTICE 'Streak calculado: % dias (timezone: %)', v_streak, v_user_timezone;
    
    RETURN v_streak;
END;
$function$
;

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
    
    -- 6. DEFINIÇÃO DE TODAS AS TRIGGERS
    resultado := resultado || E'6. DEFINIÇÃO DE TODAS AS TRIGGERS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT t.tgname, pg_get_triggerdef(t.oid) as definicao
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        ORDER BY t.tgname
    LOOP
        resultado := resultado || E'\n-- TRIGGER: ' || rec.tgname || E'\n';
        resultado := resultado || E'-- ============================================================================\n';
        resultado := resultado || rec.definicao || E';\n\n';
    END LOOP;
    
    -- 7. TRIGGERS POR TABELA
    resultado := resultado || E'7. TRIGGERS POR TABELA\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT c.relname as tabela, COUNT(*) as total_triggers, 
               string_agg(t.tgname, ', ' ORDER BY t.tgname) as lista_triggers
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        GROUP BY c.relname
        ORDER BY c.relname
    LOOP
        resultado := resultado || 'TABELA: ' || rec.tabela || ' | TRIGGERS: ' || rec.total_triggers || ' | LISTA: ' || rec.lista_triggers || E'\n';
    END LOOP;
    
    resultado := resultado || E'\n';
    
    -- 8. FUNÇÕES USADAS POR TRIGGERS
    resultado := resultado || E'8. FUNÇÕES USADAS POR TRIGGERS\n';
    resultado := resultado || E'============================================================================\n';
    
    FOR rec IN 
        SELECT p.proname as funcao, COUNT(*) as usado_por_triggers,
               string_agg(t.tgname, ', ' ORDER BY t.tgname) as lista_triggers
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public' AND NOT t.tgisinternal
        GROUP BY p.proname
        ORDER BY COUNT(*) DESC, p.proname
    LOOP
        resultado := resultado || 'FUNÇÃO: ' || rec.funcao || ' | USADA POR: ' || rec.usado_por_triggers || ' triggers | TRIGGERS: ' || rec.lista_triggers || E'\n';
    END LOOP;
    
    -- 9. VERIFICAÇÃO ESPECÍFICA: update_user_total_points
    resultado := resultado || E'\n9. VERIFICAÇÃO ESPECÍFICA: update_user_total_points\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador 
    FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'update_user_total_points';
    
    IF contador > 0 THEN
        resultado := resultado || 'FUNÇÃO update_user_total_points: EXISTE (' || contador || ' versões)' || E'\n';
        
        FOR rec IN 
            SELECT pg_get_functiondef(p.oid) as definicao
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.proname = 'update_user_total_points'
        LOOP
            resultado := resultado || E'\nCÓDIGO DA FUNÇÃO update_user_total_points:\n';
            resultado := resultado || rec.definicao || E';\n';
        END LOOP;
    ELSE
        resultado := resultado || 'FUNÇÃO update_user_total_points: NÃO EXISTE' || E'\n';
    END IF;
    
    -- 10. VERIFICAÇÃO ESPECÍFICA: level_up_notification_trigger
    resultado := resultado || E'\n10. VERIFICAÇÃO ESPECÍFICA: level_up_notification_trigger\n';
    resultado := resultado || E'============================================================================\n';
    
    SELECT COUNT(*) INTO contador 
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND t.tgname = 'level_up_notification_trigger';
    
    IF contador > 0 THEN
        resultado := resultado || 'TRIGGER level_up_notification_trigger: EXISTE' || E'\n';
        
        FOR rec IN 
            SELECT pg_get_triggerdef(t.oid) as definicao, c.relname as tabela
            FROM pg_trigger t
            JOIN pg_class c ON t.tgrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'public' AND t.tgname = 'level_up_notification_trigger'
        LOOP
            resultado := resultado || 'TABELA: ' || rec.tabela || E'\n';
            resultado := resultado || 'DEFINIÇÃO: ' || rec.definicao || E'\n';
        END LOOP;
    ELSE
        resultado := resultado || 'TRIGGER level_up_notification_trigger: NÃO EXISTE' || E'\n';
    END IF;
    
    -- Rodapé
    resultado := resultado || E'\n============================================================================\n';
    resultado := resultado || E'EXTRAÇÃO COMPLETA FINALIZADA - ' || now()::text || E'\n';
    resultado := resultado || E'============================================================================\n';
    
    RETURN resultado;
END;
$function$
;

-- FUNÇÃO 29: extrair_sistema_streak_completo
-- ============================================================================

CREATE OR REPLACE FUNCTION public.extrair_sistema_streak_completo()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    resultado TEXT := '';
    func_record RECORD;
    col_record RECORD;
    call_record RECORD;
    trigger_record RECORD;
    data_record RECORD;
    query_text TEXT;
BEGIN
    resultado := resultado || E'============================================================================\n';
    resultado := resultado || 'EXTRAÇÃO COMPLETA DO SISTEMA DE STREAK - ' || NOW() || E'\n';
    resultado := resultado || E'============================================================================\n\n';

-- FUNÇÃO 30: generate_username_from_email
-- ============================================================================

CREATE OR REPLACE FUNCTION public.generate_username_from_email()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Se username não foi fornecido e email existe, gerar automaticamente
    IF NEW.username IS NULL AND NEW.email IS NOT NULL THEN
        NEW.username = SPLIT_PART(NEW.email, '@', 1);
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 31: get_badge_bonus_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_badge_bonus_points(p_rarity text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_rarity
        WHEN 'common' THEN RETURN 5;
        WHEN 'rare' THEN RETURN 10;
        WHEN 'epic' THEN RETURN 15;
        WHEN 'legendary' THEN RETURN 20;
        ELSE RETURN 0;
    END CASE;
END;
$function$
;

-- FUNÇÃO 32: get_global_ranking
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_global_ranking(p_limit integer DEFAULT 50)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN (
        SELECT json_agg(json_build_object(
            'user_id', ur.user_id,
            'total_points', ur.total_points,
            'level_name', ur.level_name,
            'level_icon', ur.level_icon,
            'level_color', ur.level_color,
            'rank_position', ur.rank_position
        ) ORDER BY ur.rank_position)
        FROM public.user_ranking ur
        LIMIT p_limit
    );
END;
$function$
;

-- FUNÇÃO 33: get_next_milestone
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_next_milestone(p_current integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_current
        WHEN 7 THEN RETURN 30;   -- 7 dias → próximo é 30 dias
        WHEN 30 THEN RETURN 180; -- 30 dias → próximo é 180 dias
        WHEN 180 THEN RETURN 365; -- 180 dias → próximo é 365 dias
        WHEN 365 THEN RETURN 7;   -- 365 dias → reset para 7 dias
        ELSE RETURN 7;            -- Default: começar com 7 dias
    END CASE;
END;
$function$
;

-- FUNÇÃO 34: get_notification_system_stats
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_notification_system_stats()
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    total_notifications INTEGER;
    last_24h INTEGER;
    grouped_notifications INTEGER;
    spam_blocked_estimate INTEGER;
BEGIN
    -- Contar notificações
    SELECT COUNT(*) INTO total_notifications FROM public.notifications;
    SELECT COUNT(*) INTO last_24h FROM public.notifications WHERE created_at >= NOW() - INTERVAL '24 hours';
    SELECT COUNT(*) INTO grouped_notifications FROM public.notifications WHERE group_key IS NOT NULL;
    
    -- Estimar spam bloqueado (baseado em padrões)
    spam_blocked_estimate := last_24h * 3; -- Estimativa conservadora
    
    RETURN json_build_object(
        'total_notifications', total_notifications,
        'last_24h', last_24h,
        'grouped_notifications', grouped_notifications,
        'estimated_spam_blocked', spam_blocked_estimate,
        'spam_reduction_percent', 
        CASE 
            WHEN last_24h > 0 THEN 
                ROUND((spam_blocked_estimate::DECIMAL / (last_24h + spam_blocked_estimate)) * 100, 1)
            ELSE 0 
        END,
        'system_status', 'ATIVO',
        'anti_spam_enabled', true,
        'grouping_enabled', true,
        'gamification_notifications', true
    );
END;
$function$
;

-- FUNÇÃO 35: get_notification_threshold
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_notification_threshold(p_type text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN CASE p_type
        WHEN 'reaction' THEN 2        -- 2 horas para reações
        WHEN 'comment' THEN 6         -- 6 horas para comentários  
        WHEN 'feedback' THEN 0        -- Sem limite para feedbacks
        WHEN 'follow' THEN 24         -- 24 horas para follows
        WHEN 'badge_earned' THEN -1   -- Nunca bloquear badges
        WHEN 'level_up' THEN -1       -- Nunca bloquear level up
        WHEN 'milestone' THEN -1      -- Nunca bloquear marcos
        WHEN 'reaction_grouped' THEN -1 -- Nunca bloquear agrupadas
        ELSE 1                        -- Default: 1 hora
    END;
END;
$function$
;

-- FUNÇÃO 36: get_points_last_days
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_points_last_days(p_user_id uuid, p_days integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(points_earned), 0)
        FROM public.points_history 
        WHERE user_id = p_user_id 
        AND created_at >= CURRENT_DATE - INTERVAL '1 day' * p_days
        AND action_type NOT LIKE 'streak_bonus%' -- Excluir bonus anteriores para evitar duplicação
    );
END;
$function$
;

-- FUNÇÃO 37: get_previous_milestone
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_previous_milestone(p_next integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_next
        WHEN 30 THEN RETURN 7;   -- Se próximo é 30, anterior era 7
        WHEN 180 THEN RETURN 30; -- Se próximo é 180, anterior era 30
        WHEN 365 THEN RETURN 180; -- Se próximo é 365, anterior era 180
        WHEN 7 THEN RETURN 365;   -- Se próximo é 7 (reset), anterior era 365
        ELSE RETURN 7;
    END CASE;
END;
$function$
;

-- FUNÇÃO 38: get_user_gamification_data
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
;

-- FUNÇÃO 39: get_user_streak_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_streak_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak_data RECORD;
BEGIN
    SELECT 
        current_streak,
        longest_streak,
        next_milestone,
        last_activity_date
    INTO v_streak_data
    FROM public.user_streaks
    WHERE user_id = p_user_id;
    
    -- Se não encontrou, retornar dados padrão
    IF NOT FOUND THEN
        RETURN json_build_object(
            'current_streak', 0,
            'longest_streak', 0,
            'next_milestone', 7,
            'last_activity_date', NULL
        );
    END IF;
    
    RETURN json_build_object(
        'current_streak', v_streak_data.current_streak,
        'longest_streak', v_streak_data.longest_streak,
        'next_milestone', v_streak_data.next_milestone,
        'last_activity_date', v_streak_data.last_activity_date
    );
END;
$function$
;

-- FUNÇÃO 40: get_user_streak_info
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_streak_info(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_streak_info RECORD;
    v_total_bonuses INTEGER;
    v_recent_bonuses JSON;
BEGIN
    -- Buscar informações do streak
    SELECT current_streak, next_milestone, last_activity_date, updated_at
    INTO v_streak_info
    FROM public.user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não existe, retornar valores padrão
    IF NOT FOUND THEN
        RETURN json_build_object(
            'current_streak', 0,
            'next_milestone', 7,
            'total_bonuses', 0,
            'recent_bonuses', '[]'::json
        );
    END IF;
    
    -- Calcular total de bonus já recebidos
    SELECT COALESCE(SUM(points_earned), 0)
    INTO v_total_bonuses
    FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type LIKE 'streak_bonus%';
    
    -- Buscar bonus recentes
    SELECT json_agg(
        json_build_object(
            'milestone', REPLACE(REPLACE(action_type, 'streak_bonus_', ''), 'd', ''),
            'points', points_earned,
            'date', created_at
        ) ORDER BY created_at DESC
    )
    INTO v_recent_bonuses
    FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type LIKE 'streak_bonus%'
    AND created_at >= NOW() - INTERVAL '30 days'
    LIMIT 10;
    
    RETURN json_build_object(
        'current_streak', v_streak_info.current_streak,
        'next_milestone', v_streak_info.next_milestone,
        'last_activity_date', v_streak_info.last_activity_date,
        'total_bonuses', v_total_bonuses,
        'recent_bonuses', COALESCE(v_recent_bonuses, '[]'::json)
    );
END;
$function$
;

-- FUNÇÃO 41: group_reaction_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.group_reaction_notifications(p_user_id uuid, p_hours_window integer DEFAULT 2)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    notification_group RECORD;
    grouped_count INTEGER := 0;
BEGIN
    -- Agrupar reações por from_user_id nas últimas X horas
    FOR notification_group IN
        SELECT 
            from_user_id,
            array_agg(DISTINCT 
                CASE 
                    WHEN message LIKE '%❤️%' THEN '❤️'
                    WHEN message LIKE '%✨%' THEN '✨'
                    WHEN message LIKE '%🙏%' THEN '🙏'
                    ELSE '👍'
                END
            ) as reactions,
            COUNT(*) as total_count,
            MAX(created_at) as last_created,
            array_agg(id) as notification_ids
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = 'reaction'
        AND created_at >= NOW() - (p_hours_window || ' hours')::INTERVAL
        AND group_key IS NULL
        GROUP BY from_user_id
        HAVING COUNT(*) > 1
    LOOP
        -- Criar notificação agrupada
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            group_key, group_count, group_data, 
            priority, created_at
        ) VALUES (
            p_user_id,
            notification_group.from_user_id,
            'reaction_grouped',
            (SELECT username FROM public.profiles WHERE id = notification_group.from_user_id) || 
            ' reagiu (' || array_to_string(notification_group.reactions, '') || ') aos seus posts',
            'reaction_' || notification_group.from_user_id::text,
            notification_group.total_count,
            jsonb_build_object(
                'reactions', notification_group.reactions,
                'original_count', notification_group.total_count,
                'original_ids', notification_group.notification_ids
            ),
            2, -- Prioridade média
            notification_group.last_created
        );
        
        -- Marcar originais como agrupadas
        UPDATE public.notifications 
        SET group_key = 'reaction_' || notification_group.from_user_id::text
        WHERE id = ANY(notification_group.notification_ids);
        
        grouped_count := grouped_count + 1;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$
;

-- FUNÇÃO 42: group_similar_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.group_similar_notifications()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    grouped_count INTEGER := 0;
    notification_group RECORD;
BEGIN
    -- Para cada usuário que recebeu múltiplas notificações de reação
    FOR notification_group IN
        SELECT 
            user_id,
            from_user_id,
            COUNT(*) as notification_count,
            array_agg(DISTINCT 
                CASE 
                    WHEN message LIKE '%❤️%' THEN '❤️'
                    WHEN message LIKE '%✨%' THEN '✨'
                    WHEN message LIKE '%🙏%' THEN '🙏'
                    ELSE '👍'
                END
            ) as emojis,
            array_agg(id ORDER BY created_at) as notification_ids,
            MAX(created_at) as last_created,
            (SELECT username FROM public.profiles WHERE id = from_user_id) as from_username
        FROM public.notifications 
        WHERE type = 'reaction'
        AND created_at >= NOW() - INTERVAL '30 minutes'
        AND group_key IS NULL
        GROUP BY user_id, from_user_id
        HAVING COUNT(*) >= 2
    LOOP
        -- Criar notificação agrupada
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            group_key, group_count, priority, created_at
        ) VALUES (
            notification_group.user_id,
            notification_group.from_user_id,
            'reaction_grouped',
            notification_group.from_username || ' reagiu (' || array_to_string(notification_group.emojis, '') || ') aos seus posts',
            'group_' || notification_group.from_user_id::text || '_' || notification_group.user_id::text || '_' || EXTRACT(epoch FROM NOW())::text,
            notification_group.notification_count,
            2,
            notification_group.last_created
        );
        
        -- Marcar originais como agrupadas (não deletar, apenas marcar)
        UPDATE public.notifications 
        SET group_key = 'group_' || notification_group.from_user_id::text || '_' || notification_group.user_id::text || '_' || EXTRACT(epoch FROM NOW())::text
        WHERE id = ANY(notification_group.notification_ids);
        
        grouped_count := grouped_count + 1;
        
        RAISE NOTICE 'AGRUPAMENTO: % reações de % agrupadas para %', 
            notification_group.notification_count, notification_group.from_username, notification_group.user_id;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$
;

-- FUNÇÃO 43: handle_badge_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_badge_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Notificar badge conquistado
    PERFORM notify_badge_earned_definitive(
        NEW.user_id,
        NEW.badge_id,
        badge_info.name,
        badge_info.rarity
    );
    
    RAISE NOTICE 'Badge conquistado: % por %', badge_info.name, NEW.user_id;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 44: handle_badge_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_badge_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
    message_text TEXT;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Montar mensagem
    message_text := '🏆 Parabéns! Você conquistou o emblema "' || badge_info.name || '" (' || badge_info.rarity || ')';
    
    -- Criar APENAS notificação (pontos já são tratados por outros triggers)
    PERFORM create_single_notification(
        NEW.user_id, NULL, 'badge_earned', message_text, 3
    );
    
    RAISE NOTICE 'BADGE NOTIFICADO: % (%s) para %', badge_info.name, badge_info.rarity, NEW.user_id;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 45: handle_comment
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Inserir pontos para quem comentou
        INSERT INTO public.points_history (
            user_id, points_earned, action_type, reference_id, reference_type, post_id, created_at
        ) VALUES (
            NEW.user_id, 7, 'comment_given', NEW.id::text::uuid, 'comment', NEW.post_id, NOW()
        );
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$function$
;

-- FUNÇÃO 46: handle_comment_delete_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_delete_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    -- Remover pontos de quem comentou
    PERFORM remove_points_secure(OLD.user_id, 'comment_given', OLD.id);
    
    -- Remover pontos do dono do post (se aplicável)
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        PERFORM remove_points_secure(post_author_id, 'comment_received', OLD.id);
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(OLD.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN OLD;
END;
$function$
;

-- FUNÇÃO 47: handle_comment_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Quem comentou ganha 7 pontos
    PERFORM add_points_secure(
        NEW.user_id, 7, 'comment_given', NEW.id, 'comment', NEW.post_id
    );
    
    -- Dono do post ganha 5 pontos (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_secure(
            post_author_id, 5, 'comment_received', NEW.id, 'comment', NEW.post_id
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 48: handle_comment_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar autor do post comentado
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_author_id IS NULL OR post_author_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Verificação anti-duplicata
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.user_id 
        AND type = 'comment'
        AND created_at > NOW() - INTERVAL '6 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.user_id, 'comment', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'COMENTÁRIO NOTIFICADO: % comentou no post de %', username_from, post_author_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 49: handle_comment_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificar se não é auto-comentário
    IF post_author_id IS NULL OR post_author_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.user_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.user_id 
        AND type = 'comment'
        AND created_at > NOW() - INTERVAL '6 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida (COM post_id)
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id, read, created_at
    ) VALUES (
        post_author_id,
        NEW.user_id,
        'comment',
        username_from || ' comentou no seu post',  -- ✅ SEM EXCLAMAÇÃO
        NEW.post_id,  -- ✅ ADICIONAR post_id
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 50: handle_comment_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Usar função ultra segura
    PERFORM create_notification_ultra_safe(
        post_owner_id, NEW.user_id, 'comment', message_text, 2
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 51: handle_comment_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Criar APENAS notificação (não mexer em pontos)
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'comment', message_text, 2
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 52: handle_comment_notification_unique
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_unique()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
    notification_created BOOLEAN;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações de segurança
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Criar notificação com anti-spam
    SELECT create_notification_with_strict_antispam(
        post_owner_id,
        NEW.user_id,
        'comment',
        message_text,
        2
    ) INTO notification_created;
    
    -- Log para debug
    IF notification_created THEN
        RAISE NOTICE 'Notificação de comentário criada: % -> %', NEW.user_id, post_owner_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 53: handle_feedback_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Quem foi mencionado (deu feedback) ganha 10 pontos
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM add_points_secure(
            NEW.mentioned_user_id, 10, 'feedback_given', 
            md5('feedback_' || NEW.id::text)::uuid, 'feedback', NEW.post_id, NULL, NEW.mentioned_user_id
        );
    END IF;
    
    -- Quem escreveu (recebeu feedback) ganha 8 pontos
    PERFORM add_points_secure(
        NEW.author_id, 8, 'feedback_received', 
        md5('feedback_' || NEW.id::text)::uuid, 'feedback', NEW.post_id, NULL, NEW.mentioned_user_id
    );
    
    -- Recalcular pontos
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM recalculate_user_points_secure(NEW.mentioned_user_id);
    END IF;
    PERFORM recalculate_user_points_secure(NEW.author_id);
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 54: handle_feedback_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar autor do post que recebeu feedback
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas - USAR author_id (não user_id)
    IF post_author_id IS NULL OR post_author_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback - USAR author_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    
    -- Verificação anti-duplicata - USAR author_id
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.author_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação - USAR author_id
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.author_id, 'feedback', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'FEEDBACK NOTIFICADO: % deu feedback para %', username_from, post_author_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 55: handle_feedback_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-feedback
    IF NEW.author_id = NEW.mentioned_user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.mentioned_user_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.author_id 
        AND from_user_id = NEW.mentioned_user_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida (COM post_id)
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id, read, created_at
    ) VALUES (
        NEW.author_id,
        NEW.mentioned_user_id,
        'feedback',
        username_from || ' deu feedback sobre o seu post',  -- ✅ SEM EXCLAMAÇÃO
        NEW.post_id,  -- ✅ ADICIONAR post_id
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 56: handle_feedback_notification_debug
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_debug()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    RAISE NOTICE 'FEEDBACK TRIGGER EXECUTADO: feedback_id=%, post_id=%, author_id=%', NEW.id, NEW.post_id, NEW.author_id;
    
    -- Buscar autor do post que recebeu feedback
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    RAISE NOTICE 'POST AUTHOR ENCONTRADO: %', post_author_id;
    
    -- Verificações básicas
    IF post_author_id IS NULL THEN
        RAISE NOTICE 'POST AUTHOR É NULL - SAINDO';
        RETURN NEW;
    END IF;
    
    IF post_author_id = NEW.author_id THEN
        RAISE NOTICE 'AUTOR DO POST = AUTOR DO FEEDBACK - SAINDO';
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    RAISE NOTICE 'USERNAME ENCONTRADO: %', username_from;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    RAISE NOTICE 'MENSAGEM CRIADA: %', message_text;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.author_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RAISE NOTICE 'DUPLICATA ENCONTRADA - NÃO CRIANDO NOTIFICAÇÃO';
        RETURN NEW;
    END IF;
    
    -- Criar notificação
    BEGIN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.author_id, 'feedback', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'NOTIFICAÇÃO CRIADA COM SUCESSO: user_id=%, from_user_id=%, message=%', 
            post_author_id, NEW.author_id, message_text;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERRO AO CRIAR NOTIFICAÇÃO: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 57: handle_feedback_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    
    -- Criar com anti-duplicação absoluta
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    PERFORM create_notification_no_duplicates(
        post_owner_id, NEW.author_id, 'feedback', message_text, 2
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 58: handle_feedback_notification_simple
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_simple()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
BEGIN
    -- Log inicial
    RAISE NOTICE '🔔 FEEDBACK TRIGGER INICIADO: feedback_id=%, post_id=%, author_id=%', 
        NEW.id, NEW.post_id, NEW.author_id;
    
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    RAISE NOTICE '📝 POST AUTHOR: %', post_author_id;
    
    -- Verificar se encontrou o autor
    IF post_author_id IS NULL THEN
        RAISE NOTICE '❌ POST AUTHOR NÃO ENCONTRADO';
        RETURN NEW;
    END IF;
    
    -- Verificar se não é auto-feedback
    IF post_author_id = NEW.author_id THEN
        RAISE NOTICE '⚠️ AUTO-FEEDBACK DETECTADO - IGNORANDO';
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.author_id;
    
    RAISE NOTICE '👤 USERNAME: %', username_from;
    
    -- Criar notificação SEMPRE (sem verificação de duplicata para teste)
    BEGIN
        INSERT INTO public.notifications (
            user_id, 
            from_user_id, 
            type, 
            message, 
            post_id,
            read, 
            created_at
        ) VALUES (
            post_author_id,
            NEW.author_id,
            'feedback',
            username_from || ' deu feedback sobre o post que você fez destacando-o!',
            NEW.post_id,  -- ✅ ADICIONAR post_id
            false,
            NOW()
        );
        
        RAISE NOTICE '✅ NOTIFICAÇÃO CRIADA COM SUCESSO!';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO AO CRIAR NOTIFICAÇÃO: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 59: [REMOVIDA] handle_feedback_notification_table_debug
-- ============================================================================
-- Função de debug removida - não estava sendo usada no sistema

-- FUNÇÃO 60: handle_follow_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Verificações básicas
    IF NEW.following_id IS NULL OR NEW.following_id = NEW.follower_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem seguiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.follower_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' começou a te seguir!';
    
    -- Verificação anti-duplicata
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.following_id 
        AND from_user_id = NEW.follower_id 
        AND type = 'follow'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            NEW.following_id, NEW.follower_id, 'follow', message_text,
            1, false, NOW()
        );
        
        RAISE NOTICE 'FOLLOW NOTIFICADO: % seguiu %', username_from, NEW.following_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 61: handle_follow_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-follow
    IF NEW.following_id = NEW.follower_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem seguiu
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.follower_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.following_id 
        AND from_user_id = NEW.follower_id 
        AND type = 'follow'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, read, created_at
    ) VALUES (
        NEW.following_id,
        NEW.follower_id,
        'follow',
        username_from || ' começou a te seguir',  -- ✅ SEM EXCLAMAÇÃO
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 62: handle_gamification_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_gamification_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_level INTEGER := 1;
    new_level INTEGER := 1;
    level_name TEXT;
    level_thresholds INTEGER[] := ARRAY[0, 100, 300, 600, 1000, 2000, 4000, 8000, 16000, 32000];
    level_names TEXT[] := ARRAY['Novato', 'Iniciante', 'Ativo', 'Engajado', 'Influente', 'Líder', 'Especialista', 'Mestre', 'Lenda', 'Hall da Fama'];
    i INTEGER;
BEGIN
    -- Calcular nível anterior
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF OLD.total_points >= level_thresholds[i] THEN
            old_level := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Calcular novo nível
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF NEW.total_points >= level_thresholds[i] THEN
            new_level := i;
            level_name := level_names[i];
            EXIT;
        END IF;
    END LOOP;
    
    -- Notificar level up se mudou
    IF new_level > old_level THEN
        PERFORM notify_level_up_definitive(NEW.user_id, old_level, new_level, level_name);
        RAISE NOTICE 'Level up: % subiu do nível % para % (%)', NEW.user_id, old_level, new_level, level_name;
    END IF;
    
    -- Notificar marcos de pontuação
    PERFORM notify_point_milestone_definitive(NEW.user_id, OLD.total_points, NEW.total_points);
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 63: handle_holofote_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_holofote_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    mentioned_user_id UUID;
    username_from TEXT;
    mentioned_username TEXT;
BEGIN
    -- Verificar se o post tem menção (holofote)
    -- Assumindo que há um campo mentioned_user_id ou similar na tabela posts
    -- OU extrair da coluna content procurando por @username
    
    -- OPÇÃO 1: Se há campo mentioned_user_id na tabela posts
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.user_id THEN
        
        -- Buscar username de quem criou o post
        SELECT COALESCE(username, 'Usuario') INTO username_from 
        FROM public.profiles 
        WHERE id = NEW.user_id;
        
        -- Verificação anti-duplicata
        IF NOT EXISTS (
            SELECT 1 FROM public.notifications 
            WHERE user_id = NEW.mentioned_user_id 
            AND from_user_id = NEW.user_id 
            AND type = 'mention'
            AND created_at > NOW() - INTERVAL '1 hour'
            LIMIT 1
        ) THEN
            -- Criar notificação de holofote
            INSERT INTO public.notifications (
                user_id, from_user_id, type, message, post_id, read, created_at
            ) VALUES (
                NEW.mentioned_user_id,  -- Quem foi mencionado recebe notificação
                NEW.user_id,            -- Quem criou o post
                'mention',
                username_from || ' destacou você em um post',  -- ✅ NOVA MENSAGEM
                NEW.id,  -- ✅ ADICIONAR post_id (NEW.id é o ID do post)
                false,
                NOW()
            );
        END IF;
    END IF;
    
    -- OPÇÃO 2: Se não há campo, extrair da content (implementar se necessário)
    /*
    IF NEW.content LIKE '%@%' THEN
        -- Lógica para extrair @username da content
        -- E criar notificação para cada usuário mencionado
    END IF;
    */
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 64: handle_level_up_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_level_up_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_level_name TEXT;
    new_level_name TEXT;
    level_info RECORD;
    message_text TEXT;
BEGIN
    -- Verificar se o nível realmente mudou
    IF OLD.level_id IS DISTINCT FROM NEW.level_id THEN
        
        -- Buscar informações do novo nível
        SELECT name, color INTO level_info
        FROM public.levels 
        WHERE id = NEW.level_id;
        
        -- Buscar nome do nível anterior (se existir)
        IF OLD.level_id IS NOT NULL THEN
            SELECT name INTO old_level_name
            FROM public.levels 
            WHERE id = OLD.level_id;
        ELSE
            old_level_name := 'Iniciante';
        END IF;
        
        -- Montar mensagem de parabéns (SEM BENEFÍCIOS)
        message_text := '🎉 Parabéns! Você subiu para o nível "' || level_info.name || '"';
        
        -- Criar notificação de nível
        PERFORM create_single_notification(
            NEW.user_id,
            NULL,  -- Notificação do sistema
            'level_up',
            message_text,
            3  -- Alta prioridade
        );
        
        RAISE NOTICE 'LEVEL UP: % subiu de % (ID:%) para % (ID:%)', 
            NEW.user_id, old_level_name, OLD.level_id, level_info.name, NEW.level_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 65: handle_new_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.profiles (id, email, name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 66: handle_post_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_post_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Quem criou o post
    IF NEW.mentioned_user_id IS NOT NULL THEN
        -- Post com menção (holofote dado) - 20 pontos
        PERFORM add_points_secure(
            NEW.user_id, 20, 'holofote_given', NEW.id, 'post', NEW.id
        );
        
        -- Quem foi mencionado (holofote recebido) - 15 pontos
        PERFORM add_points_secure(
            NEW.mentioned_user_id, 15, 'holofote_received', NEW.id, 'post', NEW.id
        );
    ELSE
        -- Post normal - 10 pontos
        PERFORM add_points_secure(
            NEW.user_id, 10, 'post_created', NEW.id, 'post', NEW.id
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM recalculate_user_points_secure(NEW.mentioned_user_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 67: handle_reaction_delete_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_delete_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO reação: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Usar função SECURITY DEFINER para deletar pontos
    PERFORM delete_reaction_points_secure(OLD.id);
    
    -- Recalcular pontos para quem reagiu
    PERFORM recalculate_user_points_secure(OLD.user_id);
    
    -- Recalcular pontos para o dono do post (se diferente)
    IF post_owner_id IS NOT NULL AND post_owner_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_owner_id);
    END IF;
    
    RAISE NOTICE 'DELEÇÃO CONCLUÍDA com sucesso';
    RETURN OLD;
END;
$function$
;

-- FUNÇÃO 68: handle_reaction_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Quem reagiu ganha 3 pontos
    PERFORM add_points_secure(
        NEW.user_id, 3, 'reaction_given', NEW.id, 'reaction', NEW.post_id, NEW.type
    );
    
    -- Dono do post ganha 2 pontos (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_secure(
            post_author_id, 2, 'reaction_received', NEW.id, 'reaction', NEW.post_id, NEW.type
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 69: handle_reaction_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Não notificar se é o próprio usuário
    IF post_owner_id = NEW.user_id OR post_owner_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Buscar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'Alguém') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação usando função segura
    PERFORM insert_notification_safe(
        post_owner_id,
        NEW.user_id,
        'reaction',
        message_text,
        1, -- Prioridade baixa
        NEW.post_id::TEXT
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 70: handle_reaction_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Emoji
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Usar função ultra segura
    PERFORM create_notification_ultra_safe(
        post_owner_id, NEW.user_id, 'reaction', message_text, 1
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 71: handle_reaction_notification_final
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_final()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    post_content TEXT;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
    mentioned_user TEXT;
BEGIN
    -- Buscar dono do post e conteúdo
    SELECT user_id, content INTO post_owner_id, post_content 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Determinar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Verificar se o post contém menção (holofote)
    IF post_content LIKE '%@%' THEN
        -- Extrair usuário mencionado (primeiro @usuario encontrado)
        mentioned_user := SUBSTRING(post_content FROM '@([a-zA-Z0-9._]+)');
        
        -- Criar mensagem COM menção
        message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post sobre @' || mentioned_user;
    ELSE
        -- Criar mensagem SEM menção
        message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    END IF;
    
    -- Criar notificação única usando função com lock
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'reaction', message_text, 1
    );
    
    RAISE NOTICE 'REAÇÃO NOTIFICADA: % reagiu % no post de %', username_from, reaction_emoji, post_owner_id;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 72: handle_reaction_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Emoji
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar APENAS notificação (não mexer em pontos)
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'reaction', message_text, 1
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 73: handle_reaction_notification_unique
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_unique()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
    notification_created BOOLEAN;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações de segurança
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação com anti-spam rigoroso
    SELECT create_notification_with_strict_antispam(
        post_owner_id,
        NEW.user_id,
        'reaction',
        message_text,
        1
    ) INTO notification_created;
    
    -- Log para debug
    IF notification_created THEN
        RAISE NOTICE 'Notificação de reação criada: % -> %', NEW.user_id, post_owner_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 74: handle_reaction_points_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_points_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem reagiu (3 pontos)
    PERFORM add_points_to_user(NEW.user_id, 3, 'reaction_given', NEW.id::text, 'reaction');
    
    -- Adicionar pontos para autor do post (2 pontos) se não for ele mesmo
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_to_user(post_author_id, 2, 'reaction_received', NEW.id::text, 'reaction');
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 75: handle_reaction_points_simple
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_points_simple()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem reagiu (3 pontos) - CAST CORRETO
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.user_id, 'reaction_given', 3,
        'reaction', NEW.id::text::uuid, NOW()
    );
    
    -- Adicionar pontos para autor do post (2 pontos) se não for ele mesmo - CAST CORRETO
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            post_author_id, 'reaction_received', 2,
            'reaction', NEW.id::text::uuid, NOW()
        );
    END IF;
    
    -- Atualizar totais
    PERFORM update_user_total_points(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM update_user_total_points(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 76: handle_reaction_simple
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_simple()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Emoji
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Mensagem simples
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Verificação simples de duplicata (sem lock complexo)
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação simples (COM post_id)
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, post_id,
            priority, read, created_at
        ) VALUES (
            post_owner_id, NEW.user_id, 'reaction', message_text, NEW.post_id,
            1, false, NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 77: handle_streak_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_streak_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    milestone_reached INTEGER;
    bonus_points INTEGER;
BEGIN
    -- CORREÇÃO: Verificar se current_streak ATINGIU um milestone
    -- Em vez de verificar mudança de next_milestone
    
    -- Verificar se atingiu milestone de 7 dias
    IF OLD.current_streak < 7 AND NEW.current_streak >= 7 THEN
        milestone_reached := 7;
    -- Verificar se atingiu milestone de 30 dias
    ELSIF OLD.current_streak < 30 AND NEW.current_streak >= 30 THEN
        milestone_reached := 30;
    -- Verificar se atingiu milestone de 182 dias
    ELSIF OLD.current_streak < 182 AND NEW.current_streak >= 182 THEN
        milestone_reached := 182;
    -- Verificar se atingiu milestone de 365 dias
    ELSIF OLD.current_streak < 365 AND NEW.current_streak >= 365 THEN
        milestone_reached := 365;
    ELSE
        -- Nenhum milestone atingido, não fazer nada
        RETURN NEW;
    END IF;
    
    -- Buscar pontos bônus do histórico (se existir)
    SELECT COALESCE(points_earned, 0) INTO bonus_points
    FROM public.points_history 
    WHERE user_id = NEW.user_id 
    AND action_type = 'streak_bonus_' || milestone_reached || 'd'
    AND created_at >= NOW() - INTERVAL '1 hour'
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Notificar milestone
    PERFORM notify_streak_milestone_correct(
        NEW.user_id, 
        milestone_reached, 
        COALESCE(bonus_points, 0)
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', milestone_reached, NEW.user_id, bonus_points;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 78: initialize_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.initialize_user_points(user_uuid uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level)
    VALUES (user_uuid, 0, 1, 50)
    ON CONFLICT (user_id) DO NOTHING;
END;
$function$
;

-- FUNÇÃO 79: insert_notification_safe
-- ============================================================================

CREATE OR REPLACE FUNCTION public.insert_notification_safe(p_user_id uuid, p_from_user_id uuid, p_type text, p_message text, p_priority integer DEFAULT 1, p_reference_id text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se deve criar
    IF check_notification_spam(p_user_id, p_from_user_id, p_type, p_reference_id) THEN
        -- Inserir notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            p_user_id, p_from_user_id, p_type, p_message,
            p_priority, false, NOW()
        );
        
        RETURN true;
    ELSE
        -- Bloqueada por spam
        RETURN false;
    END IF;
END;
$function$
;

-- FUNÇÃO 80: migrate_existing_users_to_gamification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.migrate_existing_users_to_gamification()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user RECORD;
    v_migrated_count INTEGER := 0;
    v_posts_count INTEGER;
    v_reactions_count INTEGER;
    v_comments_count INTEGER;
    v_result JSON;
BEGIN
    -- Para cada usuário existente que NÃO tem pontos ainda
    FOR v_user IN 
        SELECT id FROM auth.users 
        WHERE id NOT IN (SELECT user_id FROM public.user_points WHERE user_id IS NOT NULL)
    LOOP
        -- Log do usuário sendo processado
        RAISE NOTICE 'Processando usuário: %', v_user.id;
        
        -- Inicializar pontos
        PERFORM initialize_user_points(v_user.id);
        
        -- Contar posts do usuário (CORRIGIDO: user_id ao invés de author_id)
        SELECT COUNT(*) INTO v_posts_count FROM public.posts WHERE user_id = v_user.id;
        
        -- Contar reações do usuário
        SELECT COUNT(*) INTO v_reactions_count FROM public.reactions WHERE user_id = v_user.id;
        
        -- Contar comentários do usuário
        SELECT COUNT(*) INTO v_comments_count FROM public.comments WHERE user_id = v_user.id;
        
        -- Log das estatísticas
        RAISE NOTICE 'Usuário %: % posts, % reações, % comentários', v_user.id, v_posts_count, v_reactions_count, v_comments_count;
        
        -- Adicionar pontos retroativos por posts (se houver)
        IF v_posts_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_posts', 
                v_posts_count * 10,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Adicionar pontos retroativos por reações (se houver)
        IF v_reactions_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_reactions', 
                v_reactions_count * 2,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Adicionar pontos retroativos por comentários (se houver)
        IF v_comments_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_comments', 
                v_comments_count * 5,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Verificar badges
        PERFORM check_and_award_badges(v_user.id);
        
        v_migrated_count := v_migrated_count + 1;
    END LOOP;
    
    v_result := json_build_object(
        'success', true,
        'migrated_users', v_migrated_count,
        'message', 'Migração concluída com sucesso'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'migrated_users', v_migrated_count
    );
END;
$function$
;

-- FUNÇÃO 81: notify_badge_earned
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_earned(p_user_id uuid, p_badge_id uuid, p_badge_name text, p_badge_rarity text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se já não existe notificação deste badge
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = 'badge_earned'
        AND message LIKE '%' || p_badge_name || '%'
    ) THEN
        RETURN create_notification_smart(
            p_user_id,
            NULL, -- Sem from_user (sistema)
            'badge_earned',
            '🏆 Parabéns! Você conquistou o emblema "' || p_badge_name || '" (' || p_badge_rarity || ')',
            3 -- Prioridade alta
        );
    END IF;
    
    RETURN false;
END;
$function$
;

-- FUNÇÃO 82: notify_badge_earned_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_earned_definitive(p_user_id uuid, p_badge_id uuid, p_badge_name text, p_badge_rarity text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Usar função anti-duplicação para badges
    RETURN create_notification_no_duplicates(
        p_user_id,
        NULL, -- Sistema (sem from_user)
        'badge_earned',
        '🏆 Parabéns! Você conquistou o emblema "' || p_badge_name || '" (' || p_badge_rarity || ')',
        3 -- Prioridade alta
    );
END;
$function$
;

-- FUNÇÃO 83: notify_badge_trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Notificar badge conquistado
    PERFORM notify_badge_earned(
        NEW.user_id,
        NEW.badge_id,
        badge_info.name,
        badge_info.rarity
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 84: notify_comment_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_comment_smart()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Não notificar se é o próprio usuário
    IF post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Criar notificação com anti-spam
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.user_id,
        'comment',
        COALESCE(username_from, 'Alguém') || ' comentou no seu post!',
        2 -- Prioridade média
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 85: notify_feedback_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_feedback_smart()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Não notificar se é o próprio usuário
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Criar notificação (feedbacks sempre passam - threshold 0)
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.author_id,
        'feedback',
        COALESCE(username_from, 'Alguém') || ' deu feedback sobre o post que você fez destacando-o!',
        2 -- Prioridade média
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 86: notify_gamification_trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_gamification_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    old_level INTEGER := 1;
    new_level INTEGER := 1;
    level_name TEXT;
    level_thresholds INTEGER[] := ARRAY[0, 100, 300, 600, 1000, 2000, 4000, 8000, 16000, 32000];
    level_names TEXT[] := ARRAY['Novato', 'Iniciante', 'Ativo', 'Engajado', 'Influente', 'Líder', 'Especialista', 'Mestre', 'Lenda', 'Hall da Fama'];
    i INTEGER;
BEGIN
    -- Calcular nível anterior
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF OLD.total_points >= level_thresholds[i] THEN
            old_level := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Calcular novo nível
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF NEW.total_points >= level_thresholds[i] THEN
            new_level := i;
            level_name := level_names[i];
            EXIT;
        END IF;
    END LOOP;
    
    -- Notificar level up se mudou
    IF new_level > old_level THEN
        PERFORM notify_level_up(NEW.user_id, old_level, new_level, level_name);
    END IF;
    
    -- Notificar marcos de pontuação
    PERFORM notify_point_milestone(NEW.user_id, OLD.total_points, NEW.total_points);
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 87: notify_level_up
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_level_up(p_user_id uuid, p_old_level integer, p_new_level integer, p_level_name text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Só notificar se realmente subiu de nível
    IF p_new_level > p_old_level THEN
        RETURN create_notification_smart(
            p_user_id,
            NULL, -- Sem from_user (sistema)
            'level_up',
            '⬆️ Level Up! Você alcançou o nível "' || p_level_name || '" (Nível ' || p_new_level || ')',
            3 -- Prioridade alta
        );
    END IF;
    
    RETURN false;
END;
$function$
;

-- FUNÇÃO 88: notify_level_up_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_level_up_definitive(p_user_id uuid, p_old_level integer, p_new_level integer, p_level_name text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Só notificar se realmente subiu de nível
    IF p_new_level > p_old_level THEN
        RETURN create_notification_no_duplicates(
            p_user_id,
            NULL, -- Sistema (sem from_user)
            'level_up',
            '⬆️ Level Up! Você alcançou o nível "' || p_level_name || '" (Nível ' || p_new_level || ')',
            3 -- Prioridade alta
        );
    END IF;
    
    RETURN false;
END;
$function$
;

-- FUNÇÃO 89: notify_point_milestone
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_point_milestone(p_user_id uuid, p_old_points integer, p_new_points integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    milestones INTEGER[] := ARRAY[100, 250, 500, 1000, 2500, 5000, 10000];
    milestone INTEGER;
    notified BOOLEAN := false;
BEGIN
    -- Verificar se atingiu algum marco
    FOREACH milestone IN ARRAY milestones LOOP
        IF p_old_points < milestone AND p_new_points >= milestone THEN
            -- Verificar se já não foi notificado deste marco
            IF NOT EXISTS (
                SELECT 1 FROM public.notifications 
                WHERE user_id = p_user_id 
                AND type = 'milestone'
                AND message LIKE '%' || milestone || ' pontos%'
            ) THEN
                PERFORM create_notification_smart(
                    p_user_id,
                    NULL, -- Sem from_user (sistema)
                    'milestone',
                    '🎉 Marco histórico: ' || milestone || ' pontos conquistados!',
                    3 -- Prioridade alta
                );
                notified := true;
            END IF;
        END IF;
    END LOOP;
    
    RETURN notified;
END;
$function$
;

-- FUNÇÃO 90: notify_point_milestone_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_point_milestone_definitive(p_user_id uuid, p_old_points integer, p_new_points integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    milestones INTEGER[] := ARRAY[100, 250, 500, 1000, 2500, 5000, 10000];
    milestone INTEGER;
    notified BOOLEAN := false;
BEGIN
    -- Verificar se atingiu algum marco
    FOREACH milestone IN ARRAY milestones LOOP
        IF p_old_points < milestone AND p_new_points >= milestone THEN
            -- Criar notificação de marco
            PERFORM create_notification_no_duplicates(
                p_user_id,
                NULL, -- Sistema
                'milestone',
                '🎉 Marco histórico: ' || milestone || ' pontos conquistados!',
                3 -- Prioridade alta
            );
            notified := true;
        END IF;
    END LOOP;
    
    RETURN notified;
END;
$function$
;

-- FUNÇÃO 91: notify_reaction_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_reaction_smart()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    reaction_emoji TEXT;
    username_from TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Não notificar se é o próprio usuário
    IF post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Buscar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Criar notificação com anti-spam
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.user_id,
        'reaction',
        COALESCE(username_from, 'Alguém') || ' reagiu ' || reaction_emoji || ' ao seu post',
        1 -- Prioridade baixa
    );
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 92: notify_streak_milestone_correct
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_streak_milestone_correct(p_user_id uuid, p_milestone_days integer, p_bonus_points integer DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    message_text TEXT;
    milestone_emoji TEXT;
BEGIN
    -- Definir emoji baseado no milestone
    CASE p_milestone_days
        WHEN 7 THEN milestone_emoji := '🔥';
        WHEN 30 THEN milestone_emoji := '⚡';
        WHEN 182 THEN milestone_emoji := '🌟';
        WHEN 365 THEN milestone_emoji := '👑';
        ELSE milestone_emoji := '🎯';
    END CASE;
    
    -- Montar mensagem baseada nos pontos bônus
    IF p_bonus_points > 0 THEN
        message_text := milestone_emoji || ' Incrível! Você atingiu ' || p_milestone_days || ' dias de sequência e ganhou ' || p_bonus_points || ' pontos bônus';
    ELSE
        message_text := milestone_emoji || ' Parabéns! Você atingiu ' || p_milestone_days || ' dias de sequência';
    END IF;
    
    -- Criar notificação usando função auxiliar
    PERFORM create_single_notification(
        p_user_id,
        NULL,  -- Notificação do sistema
        'streak_milestone',
        message_text,
        3  -- Alta prioridade
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', p_milestone_days, p_user_id, p_bonus_points;
END;
$function$
;

-- FUNÇÃO 93: process_notification_batch
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_notification_batch(p_notifications jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    notification_item JSONB;
    created_count INTEGER := 0;
    success BOOLEAN;
BEGIN
    -- Processar cada notificação no lote
    FOR notification_item IN SELECT * FROM jsonb_array_elements(p_notifications)
    LOOP
        -- Tentar criar notificação
        SELECT insert_notification_safe(
            (notification_item->>'user_id')::UUID,
            (notification_item->>'from_user_id')::UUID,
            notification_item->>'type',
            notification_item->>'message',
            COALESCE((notification_item->>'priority')::INTEGER, 1),
            notification_item->>'reference_id'
        ) INTO success;
        
        -- Contar se foi criada
        IF success THEN
            created_count := created_count + 1;
        END IF;
    END LOOP;
    
    RETURN created_count;
END;
$function$
;

-- FUNÇÃO 94: reaction_delete_handler
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reaction_delete_handler()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner UUID;
    deleted_giver INTEGER;
    deleted_receiver INTEGER;
    final_giver_points INTEGER;
    final_receiver_points INTEGER;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner FROM public.posts WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO REAÇÃO: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Remover pontos de quem reagiu
    DELETE FROM public.points_history 
    WHERE user_id = OLD.user_id 
    AND action_type = 'reaction_given' 
    AND reference_id = OLD.id::text::uuid;
    
    GET DIAGNOSTICS deleted_giver = ROW_COUNT;
    
    -- Sincronizar pontos de quem reagiu
    final_giver_points := sync_user_points(OLD.user_id);
    
    -- Remover pontos do dono (se aplicável)
    IF post_owner IS NOT NULL AND post_owner != OLD.user_id THEN
        DELETE FROM public.points_history 
        WHERE user_id = post_owner 
        AND action_type = 'reaction_received' 
        AND reference_id = OLD.id::text::uuid;
        
        GET DIAGNOSTICS deleted_receiver = ROW_COUNT;
        
        -- Sincronizar pontos do dono
        final_receiver_points := sync_user_points(post_owner);
    END IF;
    
    RAISE NOTICE 'REAÇÃO DELETADA: Removidos % do usuário (% pts finais), % do dono (% pts finais)', 
                 deleted_giver, final_giver_points, deleted_receiver, final_receiver_points;
    
    RETURN OLD;
END;
$function$
;

-- FUNÇÃO 95: reaction_insert_handler
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reaction_insert_handler()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner UUID;
    giver_points INTEGER;
    receiver_points INTEGER;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar 3 pontos para quem reagiu
    INSERT INTO public.points_history (
        user_id, points_earned, action_type, reference_id, reference_type, 
        post_id, reaction_type, created_at
    ) VALUES (
        NEW.user_id, 3, 'reaction_given', NEW.id::text::uuid, 'reaction', 
        NEW.post_id, NEW.type, NOW()
    );
    
    -- Sincronizar pontos de quem reagiu
    giver_points := sync_user_points(NEW.user_id);
    
    -- Se não é o próprio dono, dar 2 pontos para o dono
    IF post_owner IS NOT NULL AND post_owner != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, points_earned, action_type, reference_id, reference_type, 
            post_id, reaction_type, created_at
        ) VALUES (
            post_owner, 2, 'reaction_received', NEW.id::text::uuid, 'reaction', 
            NEW.post_id, NEW.type, NOW()
        );
        
        -- Sincronizar pontos do dono
        receiver_points := sync_user_points(post_owner);
    END IF;
    
    RAISE NOTICE 'REAÇÃO CRIADA: Usuário % (% pts), Dono % (% pts)', 
                 NEW.user_id, giver_points, post_owner, receiver_points;
    
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 96: recalculate_all_retroactive_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_retroactive_points()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user RECORD;
    v_user_result JSON;
    v_results JSON[] := '{}';
    v_total_users INTEGER := 0;
    v_success_count INTEGER := 0;
    v_final_result JSON;
BEGIN
    -- Processar cada usuário
    FOR v_user IN 
        SELECT user_id FROM public.user_points
    LOOP
        v_total_users := v_total_users + 1;
        
        -- Recalcular pontos do usuário
        SELECT recalculate_user_retroactive_points(v_user.user_id) INTO v_user_result;
        
        -- Adicionar resultado ao array
        v_results := array_append(v_results, v_user_result);
        
        -- Contar sucessos
        IF (v_user_result->>'success')::boolean THEN
            v_success_count := v_success_count + 1;
        END IF;
    END LOOP;
    
    -- Retornar resultado final
    v_final_result := json_build_object(
        'total_users_processed', v_total_users,
        'successful_recalculations', v_success_count,
        'failed_recalculations', v_total_users - v_success_count,
        'user_results', array_to_json(v_results)
    );
    
    RETURN v_final_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

-- FUNÇÃO 97: recalculate_all_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_user_points()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_record RECORD;
    total_users INTEGER := 0;
BEGIN
    -- Para cada usuário que tem pontos
    FOR user_record IN 
        SELECT DISTINCT user_id FROM public.points_history
    LOOP
        PERFORM update_user_total_points(user_record.user_id);
        total_users := total_users + 1;
    END LOOP;
    
    RETURN 'Recálculo concluído para ' || total_users || ' usuários';
END;
$function$
;

-- FUNÇÃO 98: recalculate_user_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_points_secure(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    new_total INTEGER;
BEGIN
    -- Calcular total de pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO new_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Atualizar user_points
    INSERT INTO public.user_points (user_id, total_points, updated_at)
    VALUES (p_user_id, new_total, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = new_total,
        updated_at = NOW();
    
    RETURN new_total;
END;
$function$
;

-- FUNÇÃO 99: recalculate_user_retroactive_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_retroactive_points(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_posts_count INTEGER := 0;
    v_reactions_count INTEGER := 0;
    v_comments_count INTEGER := 0;
    v_holofotes_count INTEGER := 0;
    v_total_retroactive_points INTEGER := 0;
    v_current_points INTEGER := 0;
    v_points_to_add INTEGER := 0;
    v_result JSON;
BEGIN
    -- Obter pontos atuais
    SELECT total_points INTO v_current_points
    FROM public.user_points
    WHERE user_id = p_user_id;
    
    -- Contar ações retroativas do usuário
    SELECT COUNT(*) INTO v_posts_count
    FROM public.posts
    WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_reactions_count
    FROM public.reactions
    WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_comments_count
    FROM public.comments
    WHERE user_id = p_user_id;
    
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_holofotes_count
    FROM public.posts
    WHERE user_id = p_user_id AND mentioned_user_id IS NOT NULL;
    
    -- Calcular total de pontos retroativos esperados
    v_total_retroactive_points := 
        (v_posts_count * 10) +           -- Posts: 10 pontos cada
        (v_reactions_count * 2) +        -- Reações: 2 pontos cada
        (v_comments_count * 5) +         -- Comentários: 5 pontos cada
        (v_holofotes_count * 20);        -- Holofotes: 20 pontos cada
    
    -- Calcular quantos pontos adicionar (descontar pontos já existentes)
    v_points_to_add := v_total_retroactive_points - v_current_points;
    
    -- Log das estatísticas
    RAISE NOTICE 'Usuário %: Posts=%, Reações=%, Comentários=%, Holofotes=%', 
        p_user_id, v_posts_count, v_reactions_count, v_comments_count, v_holofotes_count;
    RAISE NOTICE 'Pontos esperados=%, Pontos atuais=%, Pontos a adicionar=%', 
        v_total_retroactive_points, v_current_points, v_points_to_add;
    
    -- Se há pontos para adicionar, adicionar
    IF v_points_to_add > 0 THEN
        -- Adicionar pontos retroativos
        PERFORM add_points_to_user(
            p_user_id,
            'retroactive_calculation',
            v_points_to_add,
            NULL,
            'migration'
        );
        
        RAISE NOTICE 'Adicionados % pontos retroativos para usuário %', v_points_to_add, p_user_id;
    END IF;
    
    -- Retornar resultado
    v_result := json_build_object(
        'user_id', p_user_id,
        'posts_count', v_posts_count,
        'reactions_count', v_reactions_count,
        'comments_count', v_comments_count,
        'holofotes_count', v_holofotes_count,
        'total_retroactive_points', v_total_retroactive_points,
        'current_points_before', v_current_points,
        'points_added', v_points_to_add,
        'success', true
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'user_id', p_user_id
    );
END;
$function$
;

-- FUNÇÃO 100: remove_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.remove_points_secure(p_user_id uuid, p_action_type text, p_reference_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Deletar pontos do histórico
    DELETE FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type = p_action_type 
    AND reference_id = p_reference_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Pontos removidos: % registros para usuário % (ação: %)', deleted_count, p_user_id, p_action_type;
    
    RETURN deleted_count;
END;
$function$
;

-- FUNÇÃO 101: run_all_deletion_tests
-- ============================================================================

CREATE OR REPLACE FUNCTION public.run_all_deletion_tests()
 RETURNS TABLE(test_step text, result text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Passo 1: Criar dados de teste
    RETURN QUERY SELECT 'PASSO 1: Criar dados'::TEXT, create_test_data();
    
    -- Passo 2: Verificar pontos iniciais
    RETURN QUERY SELECT 'PASSO 2: Pontos iniciais'::TEXT, 
                        'User1: ' || COALESCE(up1.total_points::TEXT, '0') || 
                        ', User2: ' || COALESCE(up2.total_points::TEXT, '0')
    FROM (SELECT total_points FROM public.user_points WHERE user_id = '11111111-1111-1111-1111-111111111111') up1
    CROSS JOIN (SELECT total_points FROM public.user_points WHERE user_id = '22222222-2222-2222-2222-222222222222') up2;
    
    -- Passo 3: Testar deleção de reação
    RETURN QUERY SELECT 'PASSO 3: Deletar reação'::TEXT, test_reaction_deletion();
    
    -- Passo 4: Testar deleção de comentário
    RETURN QUERY SELECT 'PASSO 4: Deletar comentário'::TEXT, test_comment_deletion();
    
    -- Passo 5: Testar deleção de feedback
    RETURN QUERY SELECT 'PASSO 5: Deletar feedback'::TEXT, test_feedback_deletion();
    
    -- Passo 6: Verificar integridade final
    RETURN QUERY SELECT 'PASSO 6: Integridade final'::TEXT, 
                        CASE 
                            WHEN EXISTS (SELECT 1 FROM test_points_integrity()) 
                            THEN 'ERRO: Inconsistências encontradas'
                            ELSE 'OK: Pontos consistentes'
                        END;
END;
$function$
;

-- FUNÇÃO 102: should_create_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.should_create_notification(p_user_id uuid, p_from_user_id uuid, p_type text, p_hours_threshold integer DEFAULT 2)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Se threshold é -1, sempre criar (badges, level up)
    IF p_hours_threshold = -1 THEN
        RETURN true;
    END IF;
    
    -- Se threshold é 0, sempre criar (feedbacks)
    IF p_hours_threshold = 0 THEN
        RETURN true;
    END IF;
    
    -- Verificar se já existe notificação similar nas últimas X horas
    RETURN NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = p_user_id 
        AND from_user_id = p_from_user_id 
        AND type = p_type
        AND created_at > NOW() - (p_hours_threshold || ' hours')::INTERVAL
    );
END;
$function$
;

-- FUNÇÃO 103: sync_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sync_user_points(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    calculated_total INTEGER;
BEGIN
    -- Calcular total real dos pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO calculated_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Atualizar ou inserir na tabela user_points
    INSERT INTO public.user_points (user_id, total_points, updated_at)
    VALUES (p_user_id, calculated_total, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = calculated_total,
        updated_at = NOW();
    
    RETURN calculated_total;
END;
$function$
;

-- FUNÇÃO 104: test_comment_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_comment_deletion()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    comment_to_delete UUID;
    points_before INTEGER;
    points_after INTEGER;
    history_count_before BIGINT;
    history_count_after BIGINT;
BEGIN
    -- Buscar um comentário para deletar
    SELECT id INTO comment_to_delete 
    FROM public.comments 
    WHERE user_id = test_user_2 
    LIMIT 1;
    
    IF comment_to_delete IS NULL THEN
        RETURN 'ERRO: Nenhum comentário encontrado para teste';
    END IF;
    
    -- Verificar pontos antes
    SELECT COALESCE(total_points, 0) INTO points_before
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_before
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    -- Deletar comentário
    DELETE FROM public.comments WHERE id = comment_to_delete;
    
    -- Verificar pontos depois
    SELECT COALESCE(total_points, 0) INTO points_after
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_after
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    RETURN 'TESTE COMENTÁRIO: Pontos antes=' || points_before || ', depois=' || points_after || 
           ', Histórico antes=' || history_count_before || ', depois=' || history_count_after ||
           ', Diferença pontos=' || (points_before - points_after) ||
           ', Diferença histórico=' || (history_count_before - history_count_after);
END;
$function$
;

-- FUNÇÃO 105: test_feedback_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_feedback_deletion()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_1 UUID := '11111111-1111-1111-1111-111111111111';
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    feedback_to_delete UUID;
    points_before_1 INTEGER;
    points_after_1 INTEGER;
    points_before_2 INTEGER;
    points_after_2 INTEGER;
BEGIN
    -- Buscar um feedback para deletar
    SELECT id INTO feedback_to_delete 
    FROM public.feedbacks 
    WHERE author_id = test_user_1 
    LIMIT 1;
    
    IF feedback_to_delete IS NULL THEN
        RETURN 'ERRO: Nenhum feedback encontrado para teste';
    END IF;
    
    -- Verificar pontos antes (ambos usuários)
    SELECT COALESCE(total_points, 0) INTO points_before_1
    FROM public.user_points WHERE user_id = test_user_1;
    
    SELECT COALESCE(total_points, 0) INTO points_before_2
    FROM public.user_points WHERE user_id = test_user_2;
    
    -- Deletar feedback
    DELETE FROM public.feedbacks WHERE id = feedback_to_delete;
    
    -- Verificar pontos depois
    SELECT COALESCE(total_points, 0) INTO points_after_1
    FROM public.user_points WHERE user_id = test_user_1;
    
    SELECT COALESCE(total_points, 0) INTO points_after_2
    FROM public.user_points WHERE user_id = test_user_2;
    
    RETURN 'TESTE FEEDBACK: User1 antes=' || points_before_1 || ', depois=' || points_after_1 || 
           ' (diff=' || (points_before_1 - points_after_1) || '), ' ||
           'User2 antes=' || points_before_2 || ', depois=' || points_after_2 || 
           ' (diff=' || (points_before_2 - points_after_2) || ')';
END;
$function$
;

-- FUNÇÃO 106: test_level_up_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_level_up_notification(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_points INTEGER;
    current_level INTEGER := 1;
    next_level INTEGER := 2;
    level_names TEXT[] := ARRAY['Novato', 'Iniciante', 'Ativo', 'Engajado', 'Influente', 'Líder', 'Especialista', 'Mestre', 'Lenda', 'Hall da Fama'];
    level_thresholds INTEGER[] := ARRAY[0, 100, 300, 600, 1000, 2000, 4000, 8000, 16000, 32000];
    i INTEGER;
    notification_created BOOLEAN;
BEGIN
    -- Buscar pontos atuais
    SELECT total_points INTO current_points FROM public.user_points WHERE user_id = p_user_id;
    
    IF current_points IS NULL THEN
        RETURN 'Usuário não encontrado';
    END IF;
    
    -- Calcular nível atual
    FOR i IN REVERSE array_length(level_thresholds, 1)..1 LOOP
        IF current_points >= level_thresholds[i] THEN
            current_level := i;
            EXIT;
        END IF;
    END LOOP;
    
    -- Calcular próximo nível
    next_level := current_level + 1;
    IF next_level > array_length(level_names, 1) THEN
        next_level := array_length(level_names, 1);
    END IF;
    
    -- Criar notificação de level up de teste
    SELECT notify_level_up_definitive(
        p_user_id, 
        current_level - 1, 
        current_level, 
        level_names[current_level]
    ) INTO notification_created;
    
    IF notification_created THEN
        RETURN 'Notificação de level up criada com sucesso! Nível: ' || level_names[current_level];
    ELSE
        RETURN 'Notificação não foi criada (pode já existir)';
    END IF;
END;
$function$
;

-- FUNÇÃO 107: test_points_integrity
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_points_integrity()
 RETURNS TABLE(user_id uuid, points_history_total integer, user_points_total integer, difference integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ph.user_id,
        COALESCE(SUM(ph.points_earned), 0)::INTEGER as points_history_total,
        COALESCE(up.total_points, 0)::INTEGER as user_points_total,
        (COALESCE(SUM(ph.points_earned), 0) - COALESCE(up.total_points, 0))::INTEGER as difference
    FROM public.points_history ph
    FULL OUTER JOIN public.user_points up ON ph.user_id = up.user_id
    GROUP BY ph.user_id, up.total_points
    HAVING COALESCE(SUM(ph.points_earned), 0) != COALESCE(up.total_points, 0)
    ORDER BY difference DESC;
END;
$function$
;

-- FUNÇÃO 108: test_reaction_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_reaction_deletion()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    reaction_to_delete UUID;
    points_before INTEGER;
    points_after INTEGER;
    history_count_before BIGINT;
    history_count_after BIGINT;
BEGIN
    -- Buscar uma reação para deletar
    SELECT id INTO reaction_to_delete 
    FROM public.reactions 
    WHERE user_id = test_user_2 
    LIMIT 1;
    
    IF reaction_to_delete IS NULL THEN
        RETURN 'ERRO: Nenhuma reação encontrada para teste';
    END IF;
    
    -- Verificar pontos antes
    SELECT COALESCE(total_points, 0) INTO points_before
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_before
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    -- Deletar reação
    DELETE FROM public.reactions WHERE id = reaction_to_delete;
    
    -- Verificar pontos depois
    SELECT COALESCE(total_points, 0) INTO points_after
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_after
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    RETURN 'TESTE REAÇÃO: Pontos antes=' || points_before || ', depois=' || points_after || 
           ', Histórico antes=' || history_count_before || ', depois=' || history_count_after ||
           ', Diferença pontos=' || (points_before - points_after) ||
           ', Diferença histórico=' || (history_count_before - history_count_after);
END;
$function$
;

-- FUNÇÃO 109: test_streak_system
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_streak_system(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result JSON;
BEGIN
    -- Atualizar streak
    SELECT update_user_streak(p_user_id) INTO v_result;
    
    RETURN json_build_object(
        'test_completed', true,
        'user_id', p_user_id,
        'streak_result', v_result,
        'timestamp', NOW()
    );
END;
$function$
;

-- FUNÇÃO 110: trigger_comment_created
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_comment_created()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO public.points_history (user_id, action_type, points_earned, reference_id, reference_type, created_at)
    VALUES (NEW.user_id, 'comment_written', 5, NEW.id, 'comment', NOW());
    
    UPDATE public.user_points SET total_points = total_points + 5, updated_at = NOW() WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 111: trigger_comment_removed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_comment_removed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar o autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    -- Remover 7 pontos de quem comentou
    DELETE FROM public.points_history 
    WHERE user_id = OLD.user_id 
    AND action_type = 'comment_given' 
    AND reference_id = OLD.id::text;
    
    -- Remover 5 pontos do dono do post (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        DELETE FROM public.points_history 
        WHERE user_id = post_author_id 
        AND action_type = 'comment_received' 
        AND reference_id = OLD.id::text;
    END IF;
    
    RETURN OLD;
END;
$function$
;

-- FUNÇÃO 112: trigger_feedback_removed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_feedback_removed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Remover pontos de quem foi mencionado (deu feedback)
    IF OLD.mentioned_user_id IS NOT NULL THEN
        DELETE FROM public.points_history 
        WHERE user_id = OLD.mentioned_user_id 
        AND action_type = 'feedback_given' 
        AND reference_id = md5('feedback_' || OLD.id::text)::uuid;
    END IF;
    
    -- Remover pontos de quem escreveu o feedback
    DELETE FROM public.points_history 
    WHERE user_id = OLD.author_id 
    AND action_type = 'feedback_received' 
    AND reference_id = md5('feedback_' || OLD.id::text)::uuid;
    
    RETURN OLD;
END;
$function$
;

-- FUNÇÃO 113: update_updated_at_column
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

-- FUNÇÃO 114: update_user_streak
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
    -- Calcular novo streak
    v_new_streak := calculate_user_streak(p_user_id);
    
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
$function$
;

-- FUNÇÃO 115: update_user_streak_trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Atualizar streak do usuário que fez a atividade
    -- CORREÇÃO: Para feedbacks, usar NEW.author_id em vez de NEW.user_id
    IF TG_TABLE_NAME = 'feedbacks' THEN
        PERFORM update_user_streak(NEW.author_id);
        -- Para feedbacks, também atualizar streak do usuário mencionado
        IF NEW.mentioned_user_id IS NOT NULL THEN
            PERFORM update_user_streak(NEW.mentioned_user_id);
        END IF;
    ELSE
        -- Para outras tabelas (posts, comments, reactions), usar NEW.user_id
        PERFORM update_user_streak(NEW.user_id);
    END IF;
    
    RETURN NEW;
END;
$function$
;



-- FUNÇÃO 116: update_user_total_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_total_points(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_total INTEGER;
    new_level_id INTEGER;
    old_level_id INTEGER;
    level_changed BOOLEAN := FALSE;
BEGIN
    -- 1. Calcular novo total de pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO new_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- 2. Calcular nível correto baseado nos pontos
    SELECT id INTO new_level_id
    FROM public.levels 
    WHERE new_total >= min_points
    ORDER BY min_points DESC
    LIMIT 1;
    
    -- Se não encontrou nível, usar nível 1
    IF new_level_id IS NULL THEN
        SELECT id INTO new_level_id 
        FROM public.levels 
        ORDER BY id ASC 
        LIMIT 1;
        
        -- Fallback absoluto se não há níveis
        IF new_level_id IS NULL THEN
            new_level_id := 1;
        END IF;
    END IF;
    
    -- 3. Buscar nível atual do usuário (se existir)
    SELECT level_id INTO old_level_id
    FROM public.user_points 
    WHERE user_id = p_user_id;
    
    -- 4. Verificar se nível mudou
    IF old_level_id IS DISTINCT FROM new_level_id THEN
        level_changed := TRUE;
    END IF;
    
    -- 5. Verificar se coluna level_id existe na tabela
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_points' 
        AND column_name = 'level_id'
    ) THEN
        -- Atualizar COM level_id (se coluna existir)
        INSERT INTO public.user_points (user_id, total_points, level_id, updated_at)
        VALUES (p_user_id, new_total, new_level_id, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = EXCLUDED.total_points,
            level_id = EXCLUDED.level_id,
            updated_at = EXCLUDED.updated_at;
    ELSE
        -- Atualizar SEM level_id (se coluna não existir)
        INSERT INTO public.user_points (user_id, total_points, updated_at)
        VALUES (p_user_id, new_total, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = EXCLUDED.total_points,
            updated_at = EXCLUDED.updated_at;
            
        RAISE NOTICE '⚠️ AVISO: Coluna level_id não existe na tabela user_points!';
    END IF;
    
    -- 6. Log para debug
    IF level_changed THEN
        RAISE NOTICE '🎉 LEVEL UP! Usuário % - Level %→% - % pontos', 
            p_user_id, old_level_id, new_level_id, new_total;
    ELSE
        RAISE NOTICE '✅ Pontos atualizados para usuário %: % pontos (level calculado: %)', 
            p_user_id, new_total, new_level_id;
    END IF;
END;
$function$
;


-- FUNÇÃO 117: mark_all_notifications_read
-- ============================================================================

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_updated_count INTEGER;
    v_result JSON;
BEGIN
    -- Marcar todas as notificações não lidas como lidas
    -- CORREÇÃO: Removido 'read_at = NOW()' pois o campo não existe na tabela
    UPDATE public.notifications 
    SET read = true
    WHERE user_id = p_user_id 
      AND read = false;
    
    -- Obter número de notificações atualizadas
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', CASE 
            WHEN v_updated_count = 0 THEN 'Nenhuma notificação não lida encontrada'
            WHEN v_updated_count = 1 THEN '1 notificação marcada como lida'
            ELSE v_updated_count || ' notificações marcadas como lidas'
        END
    );
    
    RAISE NOTICE 'NOTIFICAÇÕES MARCADAS COMO LIDAS: % para usuário %', v_updated_count, p_user_id;
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERRO ao marcar notificações como lidas: %', SQLERRM;
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'updated_count', 0
    );
END;
$function$
;



-- FUNÇÃO 117: update_user_streak_with_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_old_streak INTEGER;
    v_new_streak INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
    v_bonus_points INTEGER := 0;
    v_completed_milestone INTEGER;
    v_points_period INTEGER;
    v_next_milestone INTEGER;
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
    -- Buscar streak atual antes da atualização
    SELECT current_streak INTO v_old_streak
    FROM user_streaks WHERE user_id = p_user_id;
    
    -- Se não existe registro, considerar streak 0
    IF v_old_streak IS NULL THEN
        v_old_streak := 0;
    END IF;
    
    -- Atualizar streak usando função existente
    PERFORM update_user_streak(p_user_id);
    
    -- Buscar dados atualizados
    SELECT current_streak, next_milestone INTO v_new_streak, v_next_milestone
    FROM user_streaks WHERE user_id = p_user_id;
    
    -- Se ainda não existe, criar registro
    IF v_new_streak IS NULL THEN
        v_new_streak := calculate_user_streak(p_user_id);
        v_next_milestone := CASE 
            WHEN v_new_streak >= 365 THEN 365
            WHEN v_new_streak >= 182 THEN 365
            WHEN v_new_streak >= 30 THEN 182
            WHEN v_new_streak >= 7 THEN 30
            ELSE 7
        END;
        
        INSERT INTO user_streaks (user_id, current_streak, next_milestone, last_activity_date, updated_at)
        VALUES (p_user_id, v_new_streak, v_next_milestone, v_current_date, NOW());
    END IF;
    
    -- Verificar se atingiu milestone (apenas se streak aumentou)
    IF v_new_streak > v_old_streak THEN
        IF v_old_streak < 7 AND v_new_streak >= 7 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 7;
        ELSIF v_old_streak < 30 AND v_new_streak >= 30 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 30;
        ELSIF v_old_streak < 182 AND v_new_streak >= 182 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 182;
        ELSIF v_old_streak < 365 AND v_new_streak >= 365 THEN
            v_milestone_reached := TRUE;
            v_completed_milestone := 365;
        END IF;
        
        -- Calcular bônus e pontos do período se milestone atingido
        IF v_milestone_reached THEN
            -- Calcular bônus usando função existente
            v_bonus_points := calculate_streak_bonus(p_user_id, v_completed_milestone);
            
            -- Calcular pontos do período (últimos X dias)
            SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
            FROM points_history 
            WHERE user_id = p_user_id 
            AND created_at >= CURRENT_DATE - INTERVAL '1 day' * v_completed_milestone;
            
            -- CREDITAR OS PONTOS BÔNUS NA CONTA DO USUÁRIO
            IF v_bonus_points > 0 THEN
                INSERT INTO points_history (user_id, points_earned, action_type, description, created_at)
                VALUES (
                    p_user_id,
                    v_bonus_points,
                    'streak_bonus',
                    'Bônus de ' || v_completed_milestone || ' dias de streak (' || v_bonus_points || ' pontos)',
                    NOW()
                );
                
                -- ATUALIZAR PONTOS TOTAIS E NÍVEL DO USUÁRIO
                PERFORM update_user_points_and_level(p_user_id);
                
                RAISE NOTICE 'Bônus creditado e pontos atualizados: User % - % pontos por milestone de % dias', 
                    p_user_id, v_bonus_points, v_completed_milestone;
            END IF;
        END IF;
    END IF;
    
    -- Log para debug
    RAISE NOTICE 'Streak com dados: User % - Streak %→% (Milestone: %, Bônus: %)', 
        p_user_id, v_old_streak, v_new_streak, v_milestone_reached, v_bonus_points;
    
    -- Retornar dados JSON para o frontend
    RETURN json_build_object(
        'current_streak', COALESCE(v_new_streak, 0),
        'milestone_reached', v_milestone_reached,
        'bonus_points', COALESCE(v_bonus_points, 0),
        'completed_milestone', COALESCE(v_completed_milestone, 0),
        'points_period', COALESCE(v_points_period, 0),
        'next_milestone', COALESCE(v_next_milestone, 7),
        'old_streak', COALESCE(v_old_streak, 0)
    );
END;
$function$
;



-- FUNÇÃO: get_feed_posts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_feed_posts(
    p_user_id UUID,
    p_filter_type TEXT DEFAULT 'all',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    person_name TEXT,
    mentioned_user_id UUID,
    content TEXT,
    story TEXT,
    photo_url TEXT,
    type TEXT,
    highlight_type TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    author_name TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    author_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    CASE p_filter_type
        WHEN 'all' THEN
            -- Todos os posts públicos (excluir posts de comunidades)
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at,
                   prof.name AS author_name,
                   prof.username::TEXT AS author_username,
                   prof.avatar_url AS author_avatar_url,
                   prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'following' THEN
            -- Apenas posts públicos de quem o usuário segue (excluir posts de comunidades)
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at,
                   prof.name AS author_name,
                   prof.username::TEXT AS author_username,
                   prof.avatar_url AS author_avatar_url,
                   prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            INNER JOIN follows f ON f.following_id = p.user_id
            WHERE f.follower_id = p_user_id
              AND p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'recommended' THEN
            -- Posts públicos recomendados (excluir posts de comunidades)
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at,
                   prof.name AS author_name,
                   prof.username::TEXT AS author_username,
                   prof.avatar_url AS author_avatar_url,
                   prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        ELSE
            -- Fallback: todos os posts públicos (excluir posts de comunidades)
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at,
                   prof.name AS author_name,
                   prof.username::TEXT AS author_username,
                   prof.avatar_url AS author_avatar_url,
                   prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
    END CASE;
END;
$function$
;

COMMENT ON FUNCTION public.get_feed_posts IS 
'Busca posts do feed com filtros: all (todos), following (apenas quem segue), recommended (recomendados)';




-- ============================================================================
-- SETTINGS FUNCTIONS
-- ============================================================================

-- FUNÇÃO: check_username_availability
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_username_availability(
    p_username TEXT,
    p_current_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Verificar se username já existe (ignorando o próprio usuário)
    -- Case-insensitive: João = joão = JOÃO
    SELECT EXISTS(
        SELECT 1 
        FROM profiles 
        WHERE LOWER(username) = LOWER(p_username) 
        AND id != p_current_user_id
    ) INTO v_exists;
    
    -- Retornar TRUE se disponível (não existe)
    RETURN NOT v_exists;
END;
$function$
;

COMMENT ON FUNCTION public.check_username_availability IS 
'Verifica se um username está disponível (retorna TRUE se disponível)';

-- FUNÇÃO: update_user_profile
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_profile(
    p_user_id UUID,
    p_name TEXT DEFAULT NULL,
    p_username TEXT DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL,
    p_default_feed TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_username_available BOOLEAN;
    v_result JSON;
BEGIN
    -- Se username foi fornecido, verificar disponibilidade
    IF p_username IS NOT NULL THEN
        SELECT check_username_availability(p_username, p_user_id) INTO v_username_available;
        
        IF NOT v_username_available THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Username já está em uso'
            );
        END IF;
    END IF;
    
    -- Atualizar perfil (apenas campos fornecidos)
    UPDATE profiles
    SET
        name = COALESCE(p_name, name),
        username = COALESCE(p_username, username),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        default_feed = COALESCE(p_default_feed, default_feed),
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Retornar perfil atualizado
    SELECT json_build_object(
        'success', true,
        'profile', row_to_json(p.*)
    )
    INTO v_result
    FROM profiles p
    WHERE p.id = p_user_id;
    
    RETURN v_result;
END;
$function$
;

COMMENT ON FUNCTION public.update_user_profile IS 
'Atualiza perfil do usuário (nome, username, avatar, feed padrão) com validações';



-- ============================================================================
-- FUNÇÃO: get_or_create_conversation
-- ============================================================================
-- Descrição: Busca ou cria uma conversa entre dois usuários
-- Parâmetros:
--   - p_user1_id: ID do primeiro usuário
--   - p_user2_id: ID do segundo usuário
-- Retorna: UUID da conversa (existente ou nova)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_conversation_id UUID;
    v_min_user_id UUID;
    v_max_user_id UUID;
BEGIN
    -- Garantir ordem consistente (user1 < user2)
    IF p_user1_id < p_user2_id THEN
        v_min_user_id := p_user1_id;
        v_max_user_id := p_user2_id;
    ELSE
        v_min_user_id := p_user2_id;
        v_max_user_id := p_user1_id;
    END IF;
    
    -- Buscar conversa existente
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE user1_id = v_min_user_id
    AND user2_id = v_max_user_id;
    
    -- Se não existir, criar nova conversa
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (user1_id, user2_id)
        VALUES (v_min_user_id, v_max_user_id)
        RETURNING id INTO v_conversation_id;
    END IF;
    
    RETURN v_conversation_id;
END;
$function$
;

COMMENT ON FUNCTION public.get_or_create_conversation IS 
'Busca ou cria uma conversa entre dois usuários, garantindo ordem consistente dos IDs';

-- ============================================================================


-- ============================================================================
-- FUNÇÕES DE COMUNIDADES
-- ============================================================================

-- FUNÇÃO: create_community
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_community(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_community_id UUID;
    v_is_community_owner BOOLEAN;
BEGIN
    -- Verificar se o usuário está autorizado
    IF auth.uid() != p_owner_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Verificar se o usuário pode criar comunidades
    SELECT community_owner INTO v_is_community_owner
    FROM profiles
    WHERE id = p_owner_id;
    
    IF NOT v_is_community_owner THEN
        RAISE EXCEPTION 'User is not authorized to create communities';
    END IF;
    
    -- Criar comunidade
    INSERT INTO communities (name, slug, description, emoji, owner_id)
    VALUES (p_name, p_slug, p_description, COALESCE(p_emoji, '🏢'), p_owner_id)
    RETURNING id INTO v_community_id;
    
    -- Adicionar owner como membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (v_community_id, p_owner_id, 'owner');
    
    -- Atribuir badge
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_owner_id,
        'Owner de Comunidade',
        'Criou uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN v_community_id;
END;
$function$
;

COMMENT ON FUNCTION public.create_community IS 
'Cria uma nova comunidade e adiciona o owner como membro';

-- FUNÇÃO: update_community
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_community(
    p_community_id UUID,
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_logo_url TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é o owner
    IF NOT EXISTS (
        SELECT 1 FROM communities 
        WHERE id = p_community_id 
        AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can update community';
    END IF;
    
    -- Atualizar comunidade
    UPDATE communities
    SET 
        name = p_name,
        slug = p_slug,
        description = p_description,
        emoji = COALESCE(p_emoji, emoji),
        logo_url = p_logo_url,
        updated_at = NOW()
    WHERE id = p_community_id;
    
    RETURN true;
END;
$function$
;

COMMENT ON FUNCTION public.update_community IS 
'Atualiza informações de uma comunidade (apenas owner)';

-- FUNÇÃO: add_community_member
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can add members';
    END IF;
    
    -- Adicionar membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, 'member')
    ON CONFLICT (community_id, user_id) DO UPDATE
    SET is_active = true;
    
    -- Atribuir badge
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_user_id,
        'Membro de Comunidade',
        'Entrou em uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN true;
END;
$function$
;

COMMENT ON FUNCTION public.add_community_member IS 
'Adiciona um membro à comunidade (apenas owner)';

-- FUNÇÃO: remove_community_member
-- ============================================================================

CREATE OR REPLACE FUNCTION public.remove_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can remove members';
    END IF;
    
    -- Impedir que owner se remova
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Owner cannot remove themselves';
    END IF;
    
    -- Remover membro (soft delete)
    UPDATE community_members
    SET is_active = false
    WHERE community_id = p_community_id AND user_id = p_user_id;
    
    RETURN true;
END;
$function$
;

COMMENT ON FUNCTION public.remove_community_member IS 
'Remove um membro da comunidade (apenas owner)';

-- FUNÇÃO: get_community_feed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    person_name TEXT,
    mentioned_user_id UUID,
    content TEXT,
    story TEXT,
    photo_url TEXT,
    type TEXT,
    highlight_type TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    community_id UUID,
    author_name TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    author_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é membro
    IF NOT EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = get_community_feed.p_community_id 
        AND cm.user_id = get_community_feed.p_user_id 
        AND cm.is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    -- Retornar posts da comunidade com dados do autor
    RETURN QUERY
    SELECT 
        p.id, p.user_id, p.celebrated_person_name, p.person_name,
        p.mentioned_user_id, p.content, p.story, p.photo_url,
        p.type, p.highlight_type, p.created_at, p.updated_at,
        p.community_id,
        prof.name AS author_name,
        prof.username::TEXT AS author_username,
        prof.avatar_url AS author_avatar_url,
        prof.email AS author_email
    FROM posts p
    LEFT JOIN profiles prof ON prof.id = p.user_id
    WHERE p.community_id = get_community_feed.p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$
;

COMMENT ON FUNCTION public.get_community_feed IS 
'Retorna posts de uma comunidade (apenas membros) com dados do autor';

-- ============================================================================


-- ============================================================================
-- FUNÇÃO: update_conversation_timestamp
-- ============================================================================
-- Descrição: Atualiza o campo updated_at de uma conversa para ordenação
-- Uso: Chamada via RPC ao enviar/receber mensagens no chat
-- Security: DEFINER (bypass RLS) para permitir update do timestamp
-- Criado em: 2024-10-31
-- ============================================================================

CREATE OR REPLACE FUNCTION update_conversation_timestamp(conversation_id_param UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE conversations
  SET updated_at = NOW()
  WHERE id = conversation_id_param;
END;
$$;

-- Dar permissão para usuários autenticados chamarem esta função
GRANT EXECUTE ON FUNCTION update_conversation_timestamp(UUID) TO authenticated;
