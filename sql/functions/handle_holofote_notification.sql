-- ============================================================================
-- FUNÇÃO: handle_holofote_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_holofote_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    mentioned_user_id UUID;
    username_from TEXT;
    mentioned_username TEXT;
BEGIN
    -- Verificar se o post tem menção (holofote)
    IF NEW.mentioned_user_id IS NOT NULL AND NEW.mentioned_user_id != NEW.user_id THEN
        
        -- Buscar username de quem criou o post
        SELECT COALESCE(username, 'Usuario') INTO username_from 
        FROM public.profiles 
        WHERE id = NEW.user_id;
        
        -- Verificação anti-duplicata
        IF NOT EXISTS (
            SELECT 1 FROM public.notifications 
            WHERE user_id = NEW.mentioned_user_id 
            AND from_user_id = NEW.user_id 
            AND type = 'mention'
            AND created_at > NOW() - INTERVAL '1 hour'
            LIMIT 1
        ) THEN
            -- Criar notificação de holofote COM post_id GARANTIDO
            INSERT INTO public.notifications (
                user_id, from_user_id, type, message, post_id, read, created_at
            ) VALUES (
                NEW.mentioned_user_id,  -- Quem foi mencionado recebe notificação
                NEW.user_id,            -- Quem criou o post
                'mention',
                username_from || ' destacou você em um post',
                NEW.id,  -- ✅ GARANTIR post_id (NEW.id é o ID do post)
                false,
                NOW()
            );
            
            -- Log para debug
            RAISE NOTICE 'MENÇÃO NOTIFICADA: % mencionou % no post % (post_id: %)', 
                username_from, NEW.mentioned_user_id, NEW.id, NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$

