-- ============================================================================
-- FUNÇÕES DE NOTIFICATIONS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de funções: 9
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- FUNÇÃO: auto_group_all_notifications
-- ============================================================================

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

-- FUNÇÃO: check_notification_spam
-- ============================================================================

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

-- FUNÇÃO: cleanup_old_notifications
-- ============================================================================

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

-- FUNÇÃO: create_notification_no_duplicates
-- ============================================================================

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

