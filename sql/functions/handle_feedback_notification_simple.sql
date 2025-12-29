-- ============================================================================
-- FUNÇÃO: handle_feedback_notification_simple
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_notification_simple()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
    username_from TEXT;
BEGIN
    -- Log inicial
    RAISE NOTICE '🔔 FEEDBACK TRIGGER INICIADO: feedback_id=%, post_id=%, author_id=%', 
        NEW.id, NEW.post_id, NEW.author_id;
    
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    RAISE NOTICE '📝 POST AUTHOR: %', post_author_id;
    
    -- Verificar se encontrou o autor
    IF post_author_id IS NULL THEN
        RAISE NOTICE '❌ POST AUTHOR NÃO ENCONTRADO';
        RETURN NEW;
    END IF;
    
    -- Verificar se não é auto-feedback
    IF post_author_id = NEW.author_id THEN
        RAISE NOTICE '⚠️ AUTO-FEEDBACK DETECTADO - IGNORANDO';
        RETURN NEW;
    END IF;
    
    -- Buscar username
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.author_id;
    
    RAISE NOTICE '👤 USERNAME: %', username_from;
    
    -- Criar notificação SEMPRE (sem verificação de duplicata para teste)
    BEGIN
        INSERT INTO public.notifications (
            user_id, 
            from_user_id, 
            type, 
            message, 
            read, 
            created_at
        ) VALUES (
            post_author_id,
            NEW.author_id,
            'feedback',
            username_from || ' deu feedback sobre o post que você fez destacando-o!',
            false,
            NOW()
        );
        
        RAISE NOTICE '✅ NOTIFICAÇÃO CRIADA COM SUCESSO!';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ ERRO AO CRIAR NOTIFICAÇÃO: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$function$

