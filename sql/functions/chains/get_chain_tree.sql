-- ============================================================================
-- FUNÇÃO: get_chain_tree
-- ============================================================================
-- DESCRIÇÃO:
-- Constrói e retorna a estrutura hierárquica dos posts dentro de uma corrente,
-- mostrando a árvore de participação e profundidade de cada nível.
--
-- PARÂMETROS:
-- - p_chain_id: UUID da corrente
--
-- RETORNA:
-- - JSON com a árvore de posts:
--   [
--     {
--       "post_id": "uuid",
--       "author_id": "uuid",
--       "parent_post_author_id": "uuid",
--       "depth": number,
--       "created_at": "timestamp"
--     },
--     ...
--   ]
--
-- LÓGICA:
-- Utiliza consulta recursiva (CTE) para mapear as relações parent_post_author_id
-- e calcular a profundidade de cada nível.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_chain_tree(p_chain_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chain_tree JSON;
BEGIN
    -- Verificar se a corrente existe
    IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    -- Construir árvore recursiva de participação
    WITH RECURSIVE chain_tree AS (
        -- Nível 0: Post inicial do criador (parent_post_author_id IS NULL)
        SELECT 
            cp.post_id,
            cp.author_id,
            cp.parent_post_author_id,
            0 AS depth,
            cp.created_at
        FROM public.chain_posts cp
        WHERE cp.chain_id = p_chain_id
        AND cp.parent_post_author_id IS NULL
        
        UNION ALL
        
        -- Níveis subsequentes: Posts de participantes
        SELECT 
            cp.post_id,
            cp.author_id,
            cp.parent_post_author_id,
            ct.depth + 1 AS depth,
            cp.created_at
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
    
    -- Se não houver posts, retornar array vazio
    IF v_chain_tree IS NULL THEN
        v_chain_tree := '[]'::json;
    END IF;
    
    RETURN v_chain_tree;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao construir árvore da corrente: %', SQLERRM;
END;
$$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.get_chain_tree(UUID) IS 
'Retorna a estrutura hierárquica de posts de uma corrente em formato JSON, com profundidade de cada nível.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados e anônimos executem a função
GRANT EXECUTE ON FUNCTION public.get_chain_tree(UUID) TO authenticated, anon;

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
