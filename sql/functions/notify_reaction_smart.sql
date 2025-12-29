-- ============================================================================
-- FUNÇÃO: notify_reaction_smart
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
$function$

