-- ============================================================================
-- FUNÇÃO: trigger_comment_removed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_comment_removed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar o autor do post
    SELECT user_id INTO post_author_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    -- Remover 7 pontos de quem comentou
    DELETE FROM public.points_history 
    WHERE user_id = OLD.user_id 
    AND action_type = 'comment_given' 
    AND reference_id = OLD.id::text;
    
    -- Remover 5 pontos do dono do post (se não for ele mesmo)
    IF post_author_id IS NOT NULL AND post_author_id != OLD.user_id THEN
        DELETE FROM public.points_history 
        WHERE user_id = post_author_id 
        AND action_type = 'comment_received' 
        AND reference_id = OLD.id::text;
    END IF;
    
    RETURN OLD;
END;
$function$

