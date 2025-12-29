-- ============================================================================
-- FUNÇÃO: handle_reaction_points_simple
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_points_simple()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_author_id UUID;
BEGIN
    -- Buscar autor do post
    SELECT user_id INTO post_author_id FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar pontos para quem reagiu (3 pontos) - CAST CORRETO
    INSERT INTO public.points_history (
        user_id, action_type, points_earned, 
        reference_type, reference_id, created_at
    ) VALUES (
        NEW.user_id, 'reaction_given', 3,
        'reaction', NEW.id::text::uuid, NOW()
    );
    
    -- Adicionar pontos para autor do post (2 pontos) se não for ele mesmo - CAST CORRETO
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, action_type, points_earned, 
            reference_type, reference_id, created_at
        ) VALUES (
            post_author_id, 'reaction_received', 2,
            'reaction', NEW.id::text::uuid, NOW()
        );
    END IF;
    
    -- Atualizar totais
    PERFORM update_user_total_points(NEW.user_id);
    IF post_author_id IS NOT NULL AND post_author_id != NEW.user_id THEN
        PERFORM update_user_total_points(post_author_id);
    END IF;
    
    RETURN NEW;
END;
$function$

