-- ============================================================================
-- FIX: Corrigir função count_user_participated_chains
-- ============================================================================
-- PROBLEMA: Função usa user_id mas tabela chain_posts tem author_id
-- SOLUÇÃO: Corrigir para usar author_id
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
$function$;

COMMENT ON FUNCTION public.count_user_participated_chains IS 'Conta quantas correntes distintas o usuário participou (CORRIGIDO: usa author_id)';

-- ✅ Função corrigida
