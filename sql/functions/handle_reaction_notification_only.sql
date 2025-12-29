-- ============================================================================
-- FUNÇÃO: handle_reaction_notification_only
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
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
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

