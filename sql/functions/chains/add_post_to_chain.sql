-- ============================================================================
-- FUNÇÃO: add_post_to_chain
-- ============================================================================
-- DESCRIÇÃO:
-- Vincula um post a uma corrente e registra a participação na tabela chain_posts.
-- Se for o primeiro post (criador), atualiza a corrente para status 'active'.
--
-- PARÂMETROS:
-- - p_chain_id: UUID da corrente
-- - p_post_id: UUID do post a ser vinculado
-- - p_author_id: UUID do autor do post
-- - p_parent_post_author_id: UUID do autor do post que originou a participação (NULL para criador)
--
-- RETORNA:
-- - VOID
--
-- LÓGICA:
-- 1. Valida que a corrente existe e está ativa (ou pending se for o criador)
-- 2. Insere registro em chain_posts
-- 3. Atualiza chain_id no post
-- 4. Se for o primeiro post (parent_post_author_id = NULL):
--    - Atualiza first_post_id
--    - Muda status para 'active'
--    - Registra start_date
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_post_to_chain(
    p_chain_id UUID,
    p_post_id UUID,
    p_author_id UUID,
    p_parent_post_author_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chain_status TEXT;
    v_chain_creator_id UUID;
    v_is_first_post BOOLEAN;
BEGIN
    -- Buscar informações da corrente
    SELECT status, creator_id
    INTO v_chain_status, v_chain_creator_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    -- Verificar se a corrente existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    -- Determinar se é o primeiro post (criador)
    v_is_first_post := (p_parent_post_author_id IS NULL AND p_author_id = v_chain_creator_id);
    
    -- Validar status da corrente
    IF v_is_first_post THEN
        -- Primeiro post: corrente deve estar 'pending'
        IF v_chain_status != 'pending' THEN
            RAISE EXCEPTION 'Corrente já foi iniciada (status: %)', v_chain_status;
        END IF;
    ELSE
        -- Posts subsequentes: corrente deve estar 'active'
        IF v_chain_status != 'active' THEN
            RAISE EXCEPTION 'Corrente não está ativa para participação (status: %)', v_chain_status;
        END IF;
    END IF;
    
    -- Verificar se o post existe
    IF NOT EXISTS (SELECT 1 FROM public.posts WHERE id = p_post_id) THEN
        RAISE EXCEPTION 'Post não encontrado: %', p_post_id;
    END IF;
    
    -- Verificar se o autor existe
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_author_id) THEN
        RAISE EXCEPTION 'Autor não encontrado: %', p_author_id;
    END IF;
    
    -- Verificar se parent_post_author_id existe (se fornecido)
    IF p_parent_post_author_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_parent_post_author_id) THEN
            RAISE EXCEPTION 'Autor do post pai não encontrado: %', p_parent_post_author_id;
        END IF;
        
        -- Verificar se o post pai está na corrente
        IF NOT EXISTS (
            SELECT 1 FROM public.chain_posts
            WHERE chain_id = p_chain_id AND author_id = p_parent_post_author_id
        ) THEN
            RAISE EXCEPTION 'Autor do post pai não participa desta corrente';
        END IF;
    END IF;
    
    -- Inserir registro em chain_posts
    INSERT INTO public.chain_posts (
        chain_id,
        post_id,
        author_id,
        parent_post_author_id
    ) VALUES (
        p_chain_id,
        p_post_id,
        p_author_id,
        p_parent_post_author_id
    );
    
    -- Atualizar chain_id no post
    UPDATE public.posts
    SET chain_id = p_chain_id
    WHERE id = p_post_id;
    
    -- Se for o primeiro post, ativar a corrente
    IF v_is_first_post THEN
        UPDATE public.chains
        SET 
            first_post_id = p_post_id,
            status = 'active',
            start_date = NOW()
        WHERE id = p_chain_id;
    END IF;
    
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Post já está associado a uma corrente';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao adicionar post à corrente: %', SQLERRM;
END;
$$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.add_post_to_chain(UUID, UUID, UUID, UUID) IS 
'Vincula um post a uma corrente. Se for o primeiro post, ativa a corrente.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados executem a função
GRANT EXECUTE ON FUNCTION public.add_post_to_chain(UUID, UUID, UUID, UUID) TO authenticated;

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
