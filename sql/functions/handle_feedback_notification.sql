-- ============================================================================
-- FUNÇÃO: handle_feedback_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar autor do post que recebeu feedback
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas - USAR author_id (não user_id)
    IF post_author_id IS NULL OR post_author_id = NEW.author_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback - USAR author_id
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    
    -- Verificação anti-duplicata - USAR author_id
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.author_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação - USAR author_id
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.author_id, 'feedback', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'FEEDBACK NOTIFICADO: % deu feedback para %', username_from, post_author_id;
    END IF;
    
    RETURN NEW;
END;
$function$

