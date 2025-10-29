-- ============================================
-- FIX: WHERE clause correto
-- Problema: p.community_id = p_community_id (sempre true!)
-- Solução: Qualificar parâmetro
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
        WHERE cm.community_id = get_community_feed.p_community_id 
        AND cm.user_id = get_community_feed.p_user_id 
        AND cm.is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    -- Retornar posts da comunidade
    RETURN QUERY
    SELECT p.*
    FROM posts p
    WHERE p.community_id = get_community_feed.p_community_id  -- ✅ Qualificado!
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$;

-- ============================================
-- EXPLICAÇÃO
-- ============================================
-- PROBLEMA:
-- WHERE p.community_id = p_community_id
-- PostgreSQL compara p.community_id com ITSELF!
-- Resultado: Sempre TRUE = Retorna TODOS os posts
--
-- SOLUÇÃO:
-- WHERE p.community_id = get_community_feed.p_community_id
-- Qualifica o parâmetro com nome da função
-- Resultado: Compara com o parâmetro correto
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ WHERE clause corrigido';
    RAISE NOTICE '📝 Qualifica parâmetro: get_community_feed.p_community_id';
END $$;

