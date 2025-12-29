-- ============================================================================
-- FUNÇÃO: delete_reaction_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_reaction_points_secure(p_reaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Deletar registros de pontos relacionados à reação
    DELETE FROM public.points_history 
    WHERE reference_id = p_reaction_id 
    AND reference_type = 'reaction';
    
    RAISE NOTICE 'Deletados registros de pontos para reação %', p_reaction_id;
END;
$function$

