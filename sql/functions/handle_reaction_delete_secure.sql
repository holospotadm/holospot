-- ============================================================================
-- FUNÇÃO: handle_reaction_delete_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_reaction_delete_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    post_owner_id UUID;
BEGIN
    -- Buscar dono do post
    SELECT user_id INTO post_owner_id 
    FROM public.posts 
    WHERE id = OLD.post_id;
    
    RAISE NOTICE 'DELETANDO reação: ID=%, Usuário=%, Post=%', OLD.id, OLD.user_id, OLD.post_id;
    
    -- Usar função SECURITY DEFINER para deletar pontos
    PERFORM delete_reaction_points_secure(OLD.id);
    
    -- Recalcular pontos para quem reagiu
    PERFORM recalculate_user_points_secure(OLD.user_id);
    
    -- Recalcular pontos para o dono do post (se diferente)
    IF post_owner_id IS NOT NULL AND post_owner_id != OLD.user_id THEN
        PERFORM recalculate_user_points_secure(post_owner_id);
    END IF;
    
    RAISE NOTICE 'DELEÇÃO CONCLUÍDA com sucesso';
    RETURN OLD;
END;
$function$

