-- ============================================================================
-- FUNÇÃO: handle_reaction_notification
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
$function$

