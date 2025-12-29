-- ============================================================================
-- FUNÇÃO: handle_reaction_notification_smart
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
$function$

