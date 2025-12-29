-- ============================================================================
-- FUNÇÃO: count_user_created_chains
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_created_chains(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM chains
        WHERE creator_id = p_user_id
    );
END;
$function$

