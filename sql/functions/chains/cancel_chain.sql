-- ============================================================================
-- FUNÇÃO: cancel_chain
-- ============================================================================
-- DESCRIÇÃO:
-- Cancela (deleta) uma corrente que ainda não teve nenhum post associado.
-- Apenas o criador pode cancelar sua corrente, e apenas se status = 'pending'.
--
-- PARÂMETROS:
-- - p_chain_id: UUID da corrente a ser cancelada
-- - p_user_id: UUID do usuário que está tentando cancelar
--
-- RETORNA:
-- - BOOLEAN: true se cancelada com sucesso, false se não foi possível
--
-- VALIDAÇÕES:
-- - Usuário deve ser o criador da corrente
-- - Corrente deve estar com status 'pending'
-- - first_post_id deve ser NULL (nenhum post foi criado)
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
    -- Buscar informações da corrente
    SELECT creator_id, status, first_post_id
    INTO v_creator_id, v_status, v_first_post_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    -- Verificar se a corrente existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    -- Verificar se o usuário é o criador
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode cancelar a corrente';
    END IF;
    
    -- Verificar se a corrente está pendente
    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Apenas correntes pendentes podem ser canceladas (status atual: %)', v_status;
    END IF;
    
    -- Verificar se nenhum post foi associado
    IF v_first_post_id IS NOT NULL THEN
        RAISE EXCEPTION 'Corrente já possui posts associados e não pode ser cancelada';
    END IF;
    
    -- Deletar a corrente
    DELETE FROM public.chains
    WHERE id = p_chain_id;
    
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao cancelar corrente: %', SQLERRM;
END;
$$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.cancel_chain(UUID, UUID) IS 
'Cancela uma corrente pendente (deleta). Apenas o criador pode cancelar, e apenas se não houver posts.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados executem a função
GRANT EXECUTE ON FUNCTION public.cancel_chain(UUID, UUID) TO authenticated;

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
