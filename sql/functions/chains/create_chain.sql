-- ============================================================================
-- FUNÇÃO: create_chain
-- ============================================================================
-- DESCRIÇÃO:
-- Cria uma nova corrente com status 'pending', aguardando o primeiro post.
--
-- PARÂMETROS:
-- - p_creator_id: UUID do usuário que está criando a corrente
-- - p_name: Nome da corrente (3-50 caracteres)
-- - p_description: Descrição da corrente (10-200 caracteres)
-- - p_highlight_type: Tipo de destaque fixo (Apoio, Inspiração, etc.)
--
-- RETORNA:
-- - UUID da corrente recém-criada
--
-- VALIDAÇÕES:
-- - Nome: 3-50 caracteres (validado por CHECK constraint)
-- - Descrição: 10-200 caracteres (validado por CHECK constraint)
-- - Criador deve existir (validado por FK)
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
    -- Validar que o criador existe
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_creator_id) THEN
        RAISE EXCEPTION 'Criador não encontrado: %', p_creator_id;
    END IF;
    
    -- Validar comprimento do nome
    IF char_length(p_name) < 3 OR char_length(p_name) > 50 THEN
        RAISE EXCEPTION 'Nome da corrente deve ter entre 3 e 50 caracteres';
    END IF;
    
    -- Validar comprimento da descrição
    IF char_length(p_description) < 10 OR char_length(p_description) > 200 THEN
        RAISE EXCEPTION 'Descrição da corrente deve ter entre 10 e 200 caracteres';
    END IF;
    
    -- Validar que o tipo de destaque não está vazio
    IF p_highlight_type IS NULL OR trim(p_highlight_type) = '' THEN
        RAISE EXCEPTION 'Tipo de destaque é obrigatório';
    END IF;
    
    -- Inserir nova corrente
    INSERT INTO public.chains (
        creator_id,
        name,
        description,
        highlight_type,
        status,
        first_post_id
    ) VALUES (
        p_creator_id,
        trim(p_name),
        trim(p_description),
        p_highlight_type,
        'pending',
        NULL
    )
    RETURNING id INTO v_chain_id;
    
    RETURN v_chain_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao criar corrente: %', SQLERRM;
END;
$$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.create_chain(UUID, TEXT, TEXT, TEXT) IS 
'Cria uma nova corrente com status pending. Retorna o UUID da corrente criada.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados executem a função
GRANT EXECUTE ON FUNCTION public.create_chain(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
