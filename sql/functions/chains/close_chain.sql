-- ============================================================================
-- FUNÇÃO: close_chain
-- ============================================================================
-- DESCRIÇÃO:
-- Encerra uma corrente ativa, impedindo novas participações.
-- O histórico permanece visível, mas nenhum novo post pode ser adicionado.
--
-- **IMPLEMENTAÇÃO FUTURA**
--
-- PARÂMETROS:
-- - p_chain_id: UUID da corrente a ser fechada
-- - p_user_id: UUID do usuário que está tentando fechar
--
-- RETORNA:
-- - BOOLEAN: true se fechada com sucesso, false se não foi possível
--
-- VALIDAÇÕES:
-- - Usuário deve ser o criador da corrente
-- - Corrente deve estar com status 'active'
--
-- LÓGICA:
-- 1. Verifica se o usuário é o criador
-- 2. Verifica se a corrente está ativa
-- 3. Atualiza status para 'closed'
-- 4. Registra end_date
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
    -- Buscar informações da corrente
    SELECT creator_id, status
    INTO v_creator_id, v_status
    FROM public.chains
    WHERE id = p_chain_id;
    
    -- Verificar se a corrente existe
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    -- Verificar se o usuário é o criador
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode fechar a corrente';
    END IF;
    
    -- Verificar se a corrente está ativa
    IF v_status != 'active' THEN
        RAISE EXCEPTION 'Apenas correntes ativas podem ser fechadas (status atual: %)', v_status;
    END IF;
    
    -- Fechar a corrente
    UPDATE public.chains
    SET 
        status = 'closed',
        end_date = NOW()
    WHERE id = p_chain_id;
    
    RETURN true;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao fechar corrente: %', SQLERRM;
END;
$$;

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.close_chain(UUID, UUID) IS 
'Fecha uma corrente ativa, impedindo novas participações. Implementação futura.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados executem a função
GRANT EXECUTE ON FUNCTION public.close_chain(UUID, UUID) TO authenticated;

-- ============================================================================
-- NOTA
-- ============================================================================
-- Esta função está pronta para uso futuro. A estrutura do banco de dados
-- já suporta o fechamento de correntes (campos status, start_date, end_date).
-- A implementação no frontend será feita posteriormente.
-- ============================================================================

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
