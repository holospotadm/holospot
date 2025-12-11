-- ============================================================================
-- MIGRATION COMPLETA: Sistema de Correntes - Fase 2 (Funções SQL)
-- ============================================================================
-- DATA: 04 de Dezembro de 2025
-- DESCRIÇÃO: Cria todas as funções SQL para gerenciar o sistema de correntes
-- EXECUTAR: No Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. FUNÇÃO: create_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_chain(
    p_creator_id UUID,
    p_name TEXT,
    p_description TEXT,
    p_highlight_type TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chain_id UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_creator_id) THEN
        RAISE EXCEPTION 'Criador não encontrado: %', p_creator_id;
    END IF;
    
    IF char_length(p_name) < 3 OR char_length(p_name) > 50 THEN
        RAISE EXCEPTION 'Nome da corrente deve ter entre 3 e 50 caracteres';
    END IF;
    
    IF char_length(p_description) < 10 OR char_length(p_description) > 200 THEN
        RAISE EXCEPTION 'Descrição da corrente deve ter entre 10 e 200 caracteres';
    END IF;
    
    IF p_highlight_type IS NULL OR trim(p_highlight_type) = '' THEN
        RAISE EXCEPTION 'Tipo de destaque é obrigatório';
    END IF;
    
    INSERT INTO public.chains (
        creator_id, name, description, highlight_type, status, first_post_id
    ) VALUES (
        p_creator_id, trim(p_name), trim(p_description), p_highlight_type, 'pending', NULL
    )
    RETURNING id INTO v_chain_id;
    
    RETURN v_chain_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao criar corrente: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.create_chain(UUID, TEXT, TEXT, TEXT) IS 
'Cria uma nova corrente com status pending. Retorna o UUID da corrente criada.';

GRANT EXECUTE ON FUNCTION public.create_chain(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ============================================================================
-- 2. FUNÇÃO: cancel_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cancel_chain(
    p_chain_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_creator_id UUID;
    v_status TEXT;
    v_first_post_id UUID;
BEGIN
    SELECT creator_id, status, first_post_id
    INTO v_creator_id, v_status, v_first_post_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode cancelar a corrente';
    END IF;
    
    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Apenas correntes pendentes podem ser canceladas (status atual: %)', v_status;
    END IF;
    
    IF v_first_post_id IS NOT NULL THEN
        RAISE EXCEPTION 'Corrente já possui posts associados e não pode ser cancelada';
    END IF;
    
    DELETE FROM public.chains WHERE id = p_chain_id;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao cancelar corrente: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.cancel_chain(UUID, UUID) IS 
'Cancela uma corrente pendente (deleta). Apenas o criador pode cancelar, e apenas se não houver posts.';

GRANT EXECUTE ON FUNCTION public.cancel_chain(UUID, UUID) TO authenticated;

-- ============================================================================
-- 3. FUNÇÃO: add_post_to_chain
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
    SELECT status, creator_id
    INTO v_chain_status, v_chain_creator_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    v_is_first_post := (p_parent_post_author_id IS NULL AND p_author_id = v_chain_creator_id);
    
    IF v_is_first_post THEN
        IF v_chain_status != 'pending' THEN
            RAISE EXCEPTION 'Corrente já foi iniciada (status: %)', v_chain_status;
        END IF;
    ELSE
        IF v_chain_status != 'active' THEN
            RAISE EXCEPTION 'Corrente não está ativa para participação (status: %)', v_chain_status;
        END IF;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.posts WHERE id = p_post_id) THEN
        RAISE EXCEPTION 'Post não encontrado: %', p_post_id;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_author_id) THEN
        RAISE EXCEPTION 'Autor não encontrado: %', p_author_id;
    END IF;
    
    IF p_parent_post_author_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_parent_post_author_id) THEN
            RAISE EXCEPTION 'Autor do post pai não encontrado: %', p_parent_post_author_id;
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM public.chain_posts
            WHERE chain_id = p_chain_id AND author_id = p_parent_post_author_id
        ) THEN
            RAISE EXCEPTION 'Autor do post pai não participa desta corrente';
        END IF;
    END IF;
    
    INSERT INTO public.chain_posts (chain_id, post_id, author_id, parent_post_author_id)
    VALUES (p_chain_id, p_post_id, p_author_id, p_parent_post_author_id);
    
    UPDATE public.posts SET chain_id = p_chain_id WHERE id = p_post_id;
    
    IF v_is_first_post THEN
        UPDATE public.chains
        SET first_post_id = p_post_id, status = 'active', start_date = NOW()
        WHERE id = p_chain_id;
    END IF;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Post já está associado a uma corrente';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao adicionar post à corrente: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.add_post_to_chain(UUID, UUID, UUID, UUID) IS 
'Vincula um post a uma corrente. Se for o primeiro post, ativa a corrente.';

GRANT EXECUTE ON FUNCTION public.add_post_to_chain(UUID, UUID, UUID, UUID) TO authenticated;

-- ============================================================================
-- 4. FUNÇÃO: get_chain_info
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_chain_info(p_chain_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chain_info JSON;
    v_total_posts INTEGER;
    v_total_participants INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    SELECT COUNT(*) INTO v_total_posts
    FROM public.chain_posts WHERE chain_id = p_chain_id;
    
    SELECT COUNT(DISTINCT author_id) INTO v_total_participants
    FROM public.chain_posts WHERE chain_id = p_chain_id;
    
    SELECT json_build_object(
        'id', c.id,
        'name', c.name,
        'description', c.description,
        'highlight_type', c.highlight_type,
        'status', c.status,
        'creator_id', c.creator_id,
        'first_post_id', c.first_post_id,
        'start_date', c.start_date,
        'end_date', c.end_date,
        'created_at', c.created_at,
        'total_posts', v_total_posts,
        'total_participants', v_total_participants
    )
    INTO v_chain_info
    FROM public.chains c
    WHERE c.id = p_chain_id;
    
    RETURN v_chain_info;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao buscar informações da corrente: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.get_chain_info(UUID) IS 
'Retorna informações detalhadas de uma corrente em formato JSON, incluindo contagem de posts e participantes.';

GRANT EXECUTE ON FUNCTION public.get_chain_info(UUID) TO authenticated, anon;

-- ============================================================================
-- 5. FUNÇÃO: get_chain_tree
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
$$;

COMMENT ON FUNCTION public.get_chain_tree(UUID) IS 
'Retorna a estrutura hierárquica de posts de uma corrente em formato JSON, com profundidade de cada nível.';

GRANT EXECUTE ON FUNCTION public.get_chain_tree(UUID) TO authenticated, anon;

-- ============================================================================
-- 6. FUNÇÃO: close_chain (IMPLEMENTAÇÃO FUTURA)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.close_chain(
    p_chain_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_creator_id UUID;
    v_status TEXT;
BEGIN
    SELECT creator_id, status
    INTO v_creator_id, v_status
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode fechar a corrente';
    END IF;
    
    IF v_status != 'active' THEN
        RAISE EXCEPTION 'Apenas correntes ativas podem ser fechadas (status atual: %)', v_status;
    END IF;
    
    UPDATE public.chains
    SET status = 'closed', end_date = NOW()
    WHERE id = p_chain_id;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao fechar corrente: %', SQLERRM;
END;
$$;

COMMENT ON FUNCTION public.close_chain(UUID, UUID) IS 
'Fecha uma corrente ativa, impedindo novas participações. Implementação futura.';

GRANT EXECUTE ON FUNCTION public.close_chain(UUID, UUID) TO authenticated;

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================

DO $$
DECLARE
    v_function_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'create_chain',
        'cancel_chain',
        'add_post_to_chain',
        'get_chain_info',
        'get_chain_tree',
        'close_chain'
    );
    
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '✅ FASE 2: FUNÇÕES SQL - VERIFICAÇÃO FINAL';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    
    IF v_function_count = 6 THEN
        RAISE NOTICE '✅ Todas as 6 funções foram criadas com sucesso:';
        RAISE NOTICE '   1. create_chain';
        RAISE NOTICE '   2. cancel_chain';
        RAISE NOTICE '   3. add_post_to_chain';
        RAISE NOTICE '   4. get_chain_info';
        RAISE NOTICE '   5. get_chain_tree';
        RAISE NOTICE '   6. close_chain (implementação futura)';
    ELSE
        RAISE EXCEPTION '❌ Erro: Apenas % de 6 funções foram criadas', v_function_count;
    END IF;
    
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '🎉 FASE 2 CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '════════════════════════════════════════════════════════════';
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
