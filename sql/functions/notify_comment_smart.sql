-- ============================================================================
-- FUNÇÃO: notify_comment_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_comment_smart()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    username_from TEXT;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Não notificar se é o próprio usuário
    IF post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Criar notificação com anti-spam
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.user_id,
        'comment',
        COALESCE(username_from, 'Alguém') || ' comentou no seu post!',
        2 -- Prioridade média
    );
    
    RETURN NEW;
END;
$function$

