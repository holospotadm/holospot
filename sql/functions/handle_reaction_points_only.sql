-- ============================================================================
-- FUNÇÃO: handle_reaction_points_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_points_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem reagiu (3 pontos)
    PERFORM add_points_to_user(NEW.user_id, 3, 'reaction_given', NEW.id::text, 'reaction');
    
    -- Adicionar pontos para autor do post (2 pontos) se não for ele mesmo
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM add_points_to_user(post_author_id, 2, 'reaction_received', NEW.id::text, 'reaction');
    END IF;
    
    RETURN NEW;
END;
$function$

