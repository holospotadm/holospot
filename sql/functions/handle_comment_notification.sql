-- ============================================================================
-- FUNÇÃO: handle_comment_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Buscar autor do post comentado
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_author_id IS NULL OR post_author_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem comentou
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' comentou no seu post!';
    
    -- Verificação anti-duplicata
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.user_id 
        AND type = 'comment'
        AND created_at > NOW() - INTERVAL '6 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.user_id, 'comment', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'COMENTÁRIO NOTIFICADO: % comentou no post de %', username_from, post_author_id;
    END IF;
    
    RETURN NEW;
END;
$function$

