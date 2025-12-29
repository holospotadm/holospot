-- ============================================================================
-- FUNÇÃO: handle_feedback_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_definitive()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_owner_id IS NULL OR post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT COALESCE(username, 'Usuario') INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    
    -- Criar com anti-duplicação absoluta COM post_id
    PERFORM create_notification_no_duplicates(
        post_owner_id, NEW.author_id, 'feedback', message_text, 2, NEW.post_id
    );
    
    RETURN NEW;
END;
$function$

