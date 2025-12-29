-- ============================================================================
-- FUNÇÃO: handle_reaction_notification_definitive
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
$function$

