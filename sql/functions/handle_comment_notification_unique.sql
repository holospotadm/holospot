-- ============================================================================
-- FUNÇÃO: handle_comment_notification_unique
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification_unique()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
    message_text TEXT;
    notification_created BOOLEAN;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações de segurança
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Montar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Criar notificação com anti-spam
    SELECT create_notification_with_strict_antispam(
        post_owner_id,
        NEW.user_id,
        'comment',
        message_text,
        2
    ) INTO notification_created;
    
    -- Log para debug
    IF notification_created THEN
        RAISE NOTICE 'Notificação de comentário criada: % -> %', NEW.user_id, post_owner_id;
    END IF;
    
    RETURN NEW;
END;
$function$

