-- ============================================================================
-- FUNÇÃO: handle_follow_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-follow
    IF NEW.following_id = NEW.follower_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem seguiu
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.follower_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.following_id 
        AND from_user_id = NEW.follower_id 
        AND type = 'follow'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, read, created_at
    ) VALUES (
        NEW.following_id,
        NEW.follower_id,
        'follow',
        username_from || ' começou a te seguir',  -- ✅ SEM EXCLAMAÇÃO
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$function$

