-- ============================================================================
-- FUNÇÃO: handle_post_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_post_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Quem criou o post
    IF NEW.mentioned_user_id IS NOT NULL THEN
        -- Post com menção (holofote dado) - 20 pontos
        PERFORM add_points_secure(
            NEW.user_id, 20, 'holofote_given', NEW.id, 'post', NEW.id
        );
        
        -- Quem foi mencionado (holofote recebido) - 15 pontos
        PERFORM add_points_secure(
            NEW.mentioned_user_id, 15, 'holofote_received', NEW.id, 'post', NEW.id
        );
    ELSE
        -- Post normal - 10 pontos
        PERFORM add_points_secure(
            NEW.user_id, 10, 'post_created', NEW.id, 'post', NEW.id
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM recalculate_user_points_secure(NEW.mentioned_user_id);
    END IF;
    
    RETURN NEW;
END;
$function$

