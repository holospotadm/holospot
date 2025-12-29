-- ============================================================================
-- FUNÇÃO: get_user_participation_depth
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_participation_depth(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_max_depth INTEGER := 0;
    v_chain_record RECORD;
    v_depth INTEGER;
BEGIN
    -- Para cada corrente que o usuário participou
    FOR v_chain_record IN 
        SELECT DISTINCT chain_id 
        FROM chain_posts 
        WHERE user_id = p_user_id
    LOOP
        -- Calcular profundidade nesta corrente
        WITH RECURSIVE chain_tree AS (
            -- Primeiro post (criador)
            SELECT 
                cp.post_id,
                cp.user_id,
                cp.parent_post_author_id,
                0 AS depth
            FROM chain_posts cp
            WHERE cp.chain_id = v_chain_record.chain_id
            AND cp.parent_post_author_id IS NULL
            
            UNION ALL
            
            -- Posts subsequentes
            SELECT 
                cp.post_id,
                cp.user_id,
                cp.parent_post_author_id,
                ct.depth + 1
            FROM chain_posts cp
            INNER JOIN chain_tree ct ON cp.parent_post_author_id = ct.user_id
            WHERE cp.chain_id = v_chain_record.chain_id
        )
        SELECT MAX(depth) INTO v_depth
        FROM chain_tree
        WHERE user_id = p_user_id;
        
        -- Atualizar profundidade máxima
        IF v_depth > v_max_depth THEN
            v_max_depth := v_depth;
        END IF;
    END LOOP;
    
    RETURN v_max_depth;
END;
$function$

