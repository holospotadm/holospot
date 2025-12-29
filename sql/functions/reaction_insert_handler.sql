-- ============================================================================
-- FUNÇÃO: reaction_insert_handler
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reaction_insert_handler()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner UUID;
    giver_points INTEGER;
    receiver_points INTEGER;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
    
    -- Adicionar 3 pontos para quem reagiu
    INSERT INTO public.points_history (
        user_id, points_earned, action_type, reference_id, reference_type, 
        post_id, reaction_type, created_at
    ) VALUES (
        NEW.user_id, 3, 'reaction_given', NEW.id::text::uuid, 'reaction', 
        NEW.post_id, NEW.type, NOW()
    );
    
    -- Sincronizar pontos de quem reagiu
    giver_points := sync_user_points(NEW.user_id);
    
    -- Se não é o próprio dono, dar 2 pontos para o dono
    IF post_owner IS NOT NULL AND post_owner != NEW.user_id THEN
        INSERT INTO public.points_history (
            user_id, points_earned, action_type, reference_id, reference_type, 
            post_id, reaction_type, created_at
        ) VALUES (
            post_owner, 2, 'reaction_received', NEW.id::text::uuid, 'reaction', 
            NEW.post_id, NEW.type, NOW()
        );
        
        -- Sincronizar pontos do dono
        receiver_points := sync_user_points(post_owner);
    END IF;
    
    RAISE NOTICE 'REAÇÃO CRIADA: Usuário % (% pts), Dono % (% pts)', 
                 NEW.user_id, giver_points, post_owner, receiver_points;
    
    RETURN NEW;
END;
$function$

