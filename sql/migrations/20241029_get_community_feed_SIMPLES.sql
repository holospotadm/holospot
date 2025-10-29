-- ============================================
-- VERSÃO SIMPLES: get_community_feed
-- Apenas retorna posts da comunidade, sem complicação
-- ============================================

DROP FUNCTION IF EXISTS public.get_community_feed(uuid,uuid,integer,integer);

CREATE OR REPLACE FUNCTION public.get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS SETOF posts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Verificar se o usuário é membro
    IF NOT EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = p_community_id 
        AND cm.user_id = p_user_id 
        AND cm.is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    -- Retornar posts da comunidade (SIMPLES!)
    RETURN QUERY
    SELECT p.*
    FROM posts p
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$;

-- ============================================
-- EXPLICAÇÃO
-- ============================================
-- VERSÃO SIMPLES:
-- - Retorna SETOF posts (todos os campos da tabela)
-- - Sem calcular likes, comments, nada
-- - Apenas filtra por community_id
-- - Frontend usa os campos que existem
--
-- VANTAGENS:
-- - Simples e direto
-- - Sem dependências de outras tabelas
-- - Funciona mesmo se likes/comments não existem
-- - Frontend já sabe lidar com posts
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Função get_community_feed SIMPLES';
    RAISE NOTICE '📝 Retorna SETOF posts (todos os campos)';
    RAISE NOTICE '📝 Sem complicações!';
END $$;

