-- ============================================================================
-- FUNÇÃO: handle_comment_delete_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment_delete_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    -- Remover pontos de quem comentou
    PERFORM remove_points_secure(OLD.user_id, 'comment_given', OLD.id);
    
    -- Remover pontos do dono do post (se aplicável)
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        PERFORM remove_points_secure(post_author_id, 'comment_received', OLD.id);
    END IF;
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(OLD.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_author_id);
    END IF;
    
    RETURN OLD;
END;
$function$

