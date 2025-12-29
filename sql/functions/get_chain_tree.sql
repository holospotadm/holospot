-- ============================================================================
-- FUNÇÃO: get_chain_tree
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_chain_tree(p_chain_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_chain_tree JSON;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    WITH RECURSIVE chain_tree AS (
        SELECT 
            cp.post_id, cp.author_id, cp.parent_post_author_id,
            0 AS depth, cp.created_at
        FROM public.chain_posts cp
        WHERE cp.chain_id = p_chain_id AND cp.parent_post_author_id IS NULL
        
        UNION ALL
        
        SELECT 
            cp.post_id, cp.author_id, cp.parent_post_author_id,
            ct.depth + 1 AS depth, cp.created_at
        FROM public.chain_posts cp
        INNER JOIN chain_tree ct ON cp.parent_post_author_id = ct.author_id
        WHERE cp.chain_id = p_chain_id
    )
    SELECT json_agg(
        json_build_object(
            'post_id', post_id,
            'author_id', author_id,
            'parent_post_author_id', parent_post_author_id,
            'depth', depth,
            'created_at', created_at
        ) ORDER BY depth, created_at
    )
    INTO v_chain_tree
    FROM chain_tree;
    
    IF v_chain_tree IS NULL THEN
        v_chain_tree := '[]'::json;
    END IF;
    
    RETURN v_chain_tree;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao construir árvore da corrente: %', SQLERRM;
END;
$function$

