-- ============================================================================
-- FUNÇÃO: handle_comment_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = NEW.post_id;
    
    -- Quem comentou ganha 7 pontos
    PERFORM add_points_secure(
        NEW.user_id, 7, 'comment_given', NEW.id, 'comment', NEW.post_id
    );
    
    -- Dono do post ganha 5 pontos (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_secure(
            post_author_id, 5, 'comment_received', NEW.id, 'comment', NEW.post_id
        );
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$

