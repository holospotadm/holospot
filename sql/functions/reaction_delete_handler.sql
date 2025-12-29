-- ============================================================================
-- FUNÇÃO: reaction_delete_handler
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reaction_delete_handler()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner UUID;
    deleted_giver INTEGER;
    deleted_receiver INTEGER;
    final_giver_points INTEGER;
    final_receiver_points INTEGER;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner FROM public.posts WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO REAÇÃO: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Remover pontos de quem reagiu
    DELETE FROM public.points_history 
    WHERE user_id = OLD.user_id 
    AND action_type = 'reaction_given' 
    AND reference_id = OLD.id::text::uuid;
    
    GET DIAGNOSTICS deleted_giver = ROW_COUNT;
    
    -- Sincronizar pontos de quem reagiu
    final_giver_points := sync_user_points(OLD.user_id);
    
    -- Remover pontos do dono (se aplicável)
    IF post_owner IS NOT NULL AND post_owner != OLD.user_id THEN
        DELETE FROM public.points_history 
        WHERE user_id = post_owner 
        AND action_type = 'reaction_received' 
        AND reference_id = OLD.id::text::uuid;
        
        GET DIAGNOSTICS deleted_receiver = ROW_COUNT;
        
        -- Sincronizar pontos do dono
        final_receiver_points := sync_user_points(post_owner);
    END IF;
    
    RAISE NOTICE 'REAÇÃO DELETADA: Removidos % do usuário (% pts finais), % do dono (% pts finais)', 
                 deleted_giver, final_giver_points, deleted_receiver, final_receiver_points;
    
    RETURN OLD;
END;
$function$

