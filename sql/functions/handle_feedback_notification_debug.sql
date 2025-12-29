-- ============================================================================
-- FUNÇÃO: handle_feedback_notification_debug
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_debug()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
    message_text TEXT;
BEGIN
    RAISE NOTICE 'FEEDBACK TRIGGER EXECUTADO: feedback_id=%, post_id=%, author_id=%', NEW.id, NEW.post_id, NEW.author_id;
    
    -- Buscar autor do post que recebeu feedback
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    RAISE NOTICE 'POST AUTHOR ENCONTRADO: %', post_author_id;
    
    -- Verificações básicas
    IF post_author_id IS NULL THEN
        RAISE NOTICE 'POST AUTHOR É NULL - SAINDO';
        RETURN NEW;
    END IF;
    
    IF post_author_id = NEW.author_id THEN
        RAISE NOTICE 'AUTOR DO POST = AUTOR DO FEEDBACK - SAINDO';
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.author_id;
    RAISE NOTICE 'USERNAME ENCONTRADO: %', username_from;
    
    -- Criar mensagem
    message_text := COALESCE(username_from, 'HoloSpot') || ' deu feedback sobre o post que você fez destacando-o!';
    RAISE NOTICE 'MENSAGEM CRIADA: %', message_text;
    
    -- Verificação anti-duplicata
    IF EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = post_author_id 
        AND from_user_id = NEW.author_id 
        AND type = 'feedback'
        AND created_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
    ) THEN
        RAISE NOTICE 'DUPLICATA ENCONTRADA - NÃO CRIANDO NOTIFICAÇÃO';
        RETURN NEW;
    END IF;
    
    -- Criar notificação
    BEGIN
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            priority, read, created_at
        ) VALUES (
            post_author_id, NEW.author_id, 'feedback', message_text,
            2, false, NOW()
        );
        
        RAISE NOTICE 'NOTIFICAÇÃO CRIADA COM SUCESSO: user_id=%, from_user_id=%, message=%', 
            post_author_id, NEW.author_id, message_text;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERRO AO CRIAR NOTIFICAÇÃO: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$function$

