-- ============================================================================
-- FUNÇÃO: handle_reaction_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_insert_secure()
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
    
    -- Quem reagiu ganha 3 pontos
    PERFORM add_points_secure(
        NEW.user_id, 3, 'reaction_given', NEW.id, 'reaction', NEW.post_id, NEW.type
    );
    
    -- Dono do post ganha 2 pontos (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_secure(
            post_author_id, 2, 'reaction_received', NEW.id, 'reaction', NEW.post_id, NEW.type
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

