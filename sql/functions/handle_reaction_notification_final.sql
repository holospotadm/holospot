-- ============================================================================
-- FUNÇÃO: handle_reaction_notification_final
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_notification_final()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
    post_content TEXT;
    reaction_emoji TEXT;
    username_from TEXT;
    message_text TEXT;
    mentioned_user TEXT;
BEGIN
    -- Buscar dono do post e conteúdo
    SELECT user_id, content INTO post_owner_id, post_content 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Verificações básicas
    IF post_owner_id IS NULL OR post_owner_id = NEW.user_id THEN
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem reagiu
    SELECT username INTO username_from FROM public.profiles WHERE id = NEW.user_id;
    
    -- Determinar emoji da reação
    reaction_emoji := CASE NEW.type
        WHEN 'touched' THEN '❤️'
        WHEN 'grateful' THEN '🙏'
        WHEN 'inspired' THEN '✨'
        ELSE '👍'
    END;
    
    -- Verificar se o post contém menção (holofote)
    IF post_content LIKE '%@%' THEN
        -- Extrair usuário mencionado (primeiro @usuario encontrado)
        mentioned_user := SUBSTRING(post_content FROM '@([a-zA-Z0-9._]+)');
        
        -- Criar mensagem COM menção
        message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post sobre @' || mentioned_user;
    ELSE
        -- Criar mensagem SEM menção
        message_text := COALESCE(username_from, 'HoloSpot') || ' reagiu ' || reaction_emoji || ' ao seu post';
    END IF;
    
    -- Criar notificação única usando função com lock
    PERFORM create_single_notification(
        post_owner_id, NEW.user_id, 'reaction', message_text, 1
    );
    
    RAISE NOTICE 'REAÇÃO NOTIFICADA: % reagiu % no post de %', username_from, reaction_emoji, post_owner_id;
    
    RETURN NEW;
END;
$function$

