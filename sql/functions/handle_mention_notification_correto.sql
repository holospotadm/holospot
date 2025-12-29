-- ============================================================================
-- FUNÇÃO: handle_mention_notification_correto
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_mention_notification_correto()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    username_from TEXT;
    message_text TEXT;
BEGIN
    -- Verificar se há mentioned_user_id (pessoa destacada)
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.user_id THEN
        -- Buscar username de quem criou o post
        SELECT COALESCE(name, email) INTO username_from
        FROM public.profiles 
        WHERE id = NEW.user_id;
        
        -- Criar mensagem
        message_text := COALESCE(username_from, 'Alguém') || ' destacou você em um post';
        
        -- Inserir notificação COM post_id
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, post_id, read, created_at
        ) VALUES (
            NEW.mentioned_user_id, NEW.user_id, 'mention', message_text, NEW.id, false, NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$function$

