-- ============================================
-- FIX FINAL: Ambiguous user_id
-- Problema: Conflito entre coluna de retorno e parâmetro
-- ============================================

DROP FUNCTION IF EXISTS public.get_community_feed(uuid,uuid,integer,integer);

CREATE OR REPLACE FUNCTION public.get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    mentioned_user_id UUID,
    person_name TEXT,
    content TEXT,
    image_url TEXT,
    created_at TIMESTAMP,
    likes_count INTEGER,
    comments_count INTEGER,
    user_has_liked BOOLEAN
)
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
    
    -- Retornar posts da comunidade
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.celebrated_person_name,
        p.mentioned_user_id,
        p.person_name,
        p.content,
        p.image_url,
        p.created_at,
        p.likes_count,
        p.comments_count,
        EXISTS(
            SELECT 1 
            FROM likes l 
            WHERE l.post_id = p.id 
            AND l.user_id = get_community_feed.p_user_id  -- ✅ Nome completo da função
        ) as user_has_liked
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
-- PROBLEMA: 
-- - RETURNS TABLE tem coluna "user_id"
-- - Parâmetro é "p_user_id"
-- - Dentro do EXISTS, "l.user_id = p_user_id" é ambíguo
-- - PostgreSQL não sabe se é o parâmetro ou a coluna
--
-- SOLUÇÃO:
-- - Usar nome completo: "get_community_feed.p_user_id"
-- - Especifica que é o PARÂMETRO da função
-- - Também adiciona alias "cm" em community_members
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Função get_community_feed corrigida (versão final)';
    RAISE NOTICE '📝 user_id qualificado com nome da função';
END $$;

