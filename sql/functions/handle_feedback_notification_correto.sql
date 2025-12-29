-- ============================================================================
-- FUNÇÃO: handle_feedback_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    username_from TEXT;
BEGIN
    -- Verificar se não é auto-feedback
    IF NEW.author_id = NEW.mentioned_user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.mentioned_user_id;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = NEW.author_id 
        AND from_user_id = NEW.mentioned_user_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Criar notificação com mensagem corrigida COM post_id GARANTIDO
    INSERT INTO public.notifications (
        user_id, from_user_id, type, message, post_id, read, created_at
    ) VALUES (
        NEW.author_id,
        NEW.mentioned_user_id,
        'feedback',
        username_from || ' deu feedback sobre o seu post',
        NEW.post_id,  -- ✅ GARANTIR post_id
        false,
        NOW()
    );
    
    -- Log para debug
    RAISE NOTICE 'FEEDBACK NOTIFICADO: % deu feedback para % no post % (post_id: %)', 
        username_from, NEW.author_id, NEW.post_id, NEW.post_id;
    
    RETURN NEW;
END;
$function$

