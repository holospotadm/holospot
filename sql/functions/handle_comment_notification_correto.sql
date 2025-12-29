-- ============================================================================
-- FUNÇÃO: handle_comment_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_correto()
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
    SELECT user_id INTO post_owner_id
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Buscar username de quem comentou
    SELECT COALESCE(name, email) INTO username_from
    FROM public.profiles 
    WHERE id = NEW.user_id;
    
    -- Não notificar se comentou no próprio post
    IF post_owner_id != NEW.user_id THEN
        -- Criar mensagem
        message_text := COALESCE(username_from, 'Alguém') || ' comentou no seu post';
        
        -- Inserir notificação COM post_id
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, post_id, read, created_at
        ) VALUES (
            post_owner_id, NEW.user_id, 'comment', message_text, NEW.post_id, false, NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$function$

