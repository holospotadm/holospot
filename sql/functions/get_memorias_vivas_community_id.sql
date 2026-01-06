-- ============================================================================
-- FUNÇÃO: get_memorias_vivas_community_id
-- Descrição: Retorna o ID da comunidade Memórias Vivas
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_memorias_vivas_community_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
    SELECT id FROM public.communities WHERE slug = 'memorias-vivas' LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_memorias_vivas_community_id() IS 'Retorna o ID da comunidade Memórias Vivas';
