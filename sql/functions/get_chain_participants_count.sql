-- ============================================================================
-- FUNÇÃO: get_chain_participants_count
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_chain_participants_count(p_chain_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT user_id)
        FROM chain_posts
        WHERE chain_id = p_chain_id
    );
END;
$function$

