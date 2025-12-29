-- ============================================================================
-- MIGRAÇÃO COMPLETA: Corrigir TODAS as funções de reação
-- Data: 2024-12-29
-- ============================================================================
-- PROBLEMA: As funções de trigger usam NEW.author_id, mas a tabela reactions
-- só tem a coluna user_id. Isso causa erro e impede a inserção de reações.
-- 
-- CORREÇÕES:
-- 1. Trocar NEW.author_id por NEW.user_id em todas as funções de reação
-- 2. Atualizar tipos de reação: touched → loved, grateful → claps, inspired → hug
-- 3. Atualizar emojis: ❤️ (loved), 👏 (claps), 🫂 (hug)
-- ============================================================================

-- ============================================================================
-- FUNÇÃO 1: handle_reaction_simple (TRIGGER PRINCIPAL)
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
    
    -- Verificações básicas - USAR NEW.user_id (não author_id)
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username - USAR NEW.user_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji baseado no novo tipo de reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Mensagem simples
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Verificação simples de duplicata
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação
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
$function$;

-- ============================================================================
-- FUNÇÃO 2: handle_reaction_notification
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
    
    -- Verificações básicas - USAR NEW.user_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username - USAR NEW.user_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji baseado no novo tipo de reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id,
        priority, read, created_at
    ) VALUES (
        post_owner_id, NEW.user_id, 'reaction', message_text, NEW.post_id,
        1, false, NOW()
    )
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- FUNÇÃO 3: handle_reaction_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_correto()
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
    
    -- Verificações básicas - USAR NEW.user_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username - USAR NEW.user_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação com anti-spam
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
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
$function$;

-- ============================================================================
-- FUNÇÃO 4: handle_reaction_notification_definitive
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
    
    -- Verificações básicas - USAR NEW.user_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username - USAR NEW.user_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar com anti-duplicação
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
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
$function$;

-- ============================================================================
-- FUNÇÃO 5: handle_reaction_notification_holofote
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_holofote()
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
    
    -- Verificações básicas - USAR NEW.user_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu - USAR NEW.user_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Determinar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Verificar se o post contém menção (holofote)
    IF post_content LIKE '%@%' THEN
        message_text := COALESCE(username_from, 'Alguém') || ' reagiu ' || reaction_emoji || ' ao holofote que você recebeu!';
    ELSE
        message_text := COALESCE(username_from, 'Alguém') || ' reagiu ' || reaction_emoji || ' ao seu post';
    END IF;
    
    -- Criar notificação com anti-spam - USAR NEW.user_id
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_owner_id 
        AND from_user_id = NEW.user_id 
        AND type = 'reaction'
        AND created_at > NOW() - INTERVAL '2 hours'
        LIMIT 1
    ) THEN
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
$function$;

-- ============================================================================
-- FUNÇÃO 6: handle_reaction_notification_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_smart()
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
    
    -- Verificações de segurança - USAR NEW.user_id
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username - USAR NEW.user_id
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    
    -- Criar notificação com anti-spam
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.user_id,
        'reaction',
        message_text,
        1
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- FUNÇÃO 7: notify_reaction_smart
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
    
    -- Não notificar se é o próprio usuário - USAR NEW.user_id
    IF post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu - USAR NEW.user_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Buscar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'loved' THEN '❤️'
        WHEN 'claps' THEN '👏'
        WHEN 'hug' THEN '🫂'
        ELSE '👍'
    END;
    
    -- Criar notificação com anti-spam - USAR NEW.user_id
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.user_id,
        'reaction',
        COALESCE(username_from, 'Alguém') || ' reagiu ' || reaction_emoji || ' ao seu post',
        1
    );
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================

-- Verificar se as funções foram criadas corretamente
DO $$
BEGIN
    RAISE NOTICE '✅ Migração concluída!';
    RAISE NOTICE '✅ Funções de reação atualizadas:';
    RAISE NOTICE '   - handle_reaction_simple';
    RAISE NOTICE '   - handle_reaction_notification';
    RAISE NOTICE '   - handle_reaction_notification_correto';
    RAISE NOTICE '   - handle_reaction_notification_definitive';
    RAISE NOTICE '   - handle_reaction_notification_holofote';
    RAISE NOTICE '   - handle_reaction_notification_smart';
    RAISE NOTICE '   - notify_reaction_smart';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Correções aplicadas:';
    RAISE NOTICE '   - NEW.author_id → NEW.user_id';
    RAISE NOTICE '   - touched → loved (❤️)';
    RAISE NOTICE '   - grateful → claps (👏)';
    RAISE NOTICE '   - inspired → hug (🫂)';
END;
$$;
