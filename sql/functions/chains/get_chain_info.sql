-- ============================================================================
-- FUNÇÃO: get_chain_info
-- ============================================================================
-- DESCRIÇÃO:
-- Retorna informações detalhadas sobre uma corrente específica, incluindo
-- contagem de posts e participantes.
--
-- PARÂMETROS:
-- - p_chain_id: UUID da corrente
--
-- RETORNA:
-- - JSON com informações da corrente:
--   {
--     "id": "uuid",
--     "name": "string",
--     "description": "string",
--     "highlight_type": "string",
--     "status": "string",
--     "creator_id": "uuid",
--     "first_post_id": "uuid",
--     "start_date": "timestamp",
--     "end_date": "timestamp",
--     "total_posts": number,
--     "total_participants": number,
--     "created_at": "timestamp"
--   }
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
    -- Verificar se a corrente existe
    IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    -- Contar total de posts na corrente
    SELECT COUNT(*)
    INTO v_total_posts
    FROM public.chain_posts
    WHERE chain_id = p_chain_id;
    
    -- Contar total de participantes únicos
    SELECT COUNT(DISTINCT author_id)
    INTO v_total_participants
    FROM public.chain_posts
    WHERE chain_id = p_chain_id;
    
    -- Construir JSON com informações da corrente
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
        'total_participants', v_total_participants,
        'is_memorias_vivas', c.is_memorias_vivas
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

-- ============================================================================
-- COMENTÁRIO
-- ============================================================================

COMMENT ON FUNCTION public.get_chain_info(UUID) IS 
'Retorna informações detalhadas de uma corrente em formato JSON, incluindo contagem de posts e participantes.';

-- ============================================================================
-- PERMISSÕES
-- ============================================================================

-- Permitir que usuários autenticados e anônimos executem a função
GRANT EXECUTE ON FUNCTION public.get_chain_info(UUID) TO authenticated, anon;

-- ============================================================================
-- FIM DA FUNÇÃO
-- ============================================================================
