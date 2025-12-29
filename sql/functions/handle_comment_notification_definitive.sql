-- ============================================================================
-- FUNÇÃO: handle_comment_notification_definitive
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
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Usar função ultra segura
    PERFORM create_notification_ultra_safe(
        post_owner_id, NEW.user_id, 'comment', message_text, 2
    );
    
    RETURN NEW;
END;
$function$

