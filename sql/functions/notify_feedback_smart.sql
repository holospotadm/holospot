-- ============================================================================
-- FUNÇÃO: notify_feedback_smart
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_feedback_smart()
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
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    IF post_owner_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    -- CORREÇÃO: Mudado NEW.user_id para NEW.author_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Criar notificação (feedbacks sempre passam - threshold 0)
    PERFORM create_notification_smart(
        post_owner_id,
        NEW.author_id,
        'feedback',
        COALESCE(username_from, 'Alguém') || ' deu feedback sobre o post que você fez destacando-o!',
        2 -- Prioridade média
    );
    
    RETURN NEW;
END;
$function$

