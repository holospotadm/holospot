-- ============================================================================
-- FUNÇÃO: remove_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.remove_points_secure(p_user_id uuid, p_action_type text, p_reference_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Deletar pontos do histórico
    DELETE FROM public.points_history 
    WHERE user_id = p_user_id 
    AND action_type = p_action_type 
    AND reference_id = p_reference_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Pontos removidos: % registros para usuário % (ação: %)', deleted_count, p_user_id, p_action_type;
    
    RETURN deleted_count;
END;
$function$

