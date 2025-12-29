-- ============================================================================
-- FUNÇÃO: handle_follow_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Verificações básicas
    IF NEW.following_id IS NULL OR NEW.following_id = NEW.follower_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem seguiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.follower_id;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' começou a te seguir!';
    
    -- Verificação anti-duplicata
    IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.following_id 
        AND from_user_id = NEW.follower_id 
        AND type = 'follow'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        -- Criar notificação
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            NEW.following_id, NEW.follower_id, 'follow', message_text,
            1, false, NOW()
        );
        
        RAISE NOTICE 'FOLLOW NOTIFICADO: % seguiu %', username_from, NEW.following_id;
    END IF;
    
    RETURN NEW;
END;
$function$

