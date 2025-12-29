-- ============================================================================
-- FUNÇÃO: count_user_participated_chains
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_participated_chains(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT chain_id)
        FROM chain_posts
        WHERE author_id = p_user_id  -- CORRIGIDO: user_id → author_id
    );
END;
$function$

