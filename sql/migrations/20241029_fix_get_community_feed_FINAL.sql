-- ============================================
-- FIX FINAL: get_community_feed com campos corretos
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
    photo_url TEXT,
    created_at TIMESTAMPTZ,
    likes_count BIGINT,
    comments_count BIGINT,
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
        p.photo_url,
        p.created_at,
        -- Contar likes dinamicamente
        (SELECT COUNT(*) FROM likes l WHERE l.post_id = p.id)::BIGINT as likes_count,
        -- Contar comentários dinamicamente
        (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id)::BIGINT as comments_count,
        -- Verificar se usuário curtiu
        EXISTS(
            SELECT 1 
            FROM likes l 
            WHERE l.post_id = p.id 
            AND l.user_id = get_community_feed.p_user_id
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
-- CAMPOS DA TABELA POSTS (real):
-- - id, user_id, celebrated_person_name, content
-- - type, photo_url, created_at, updated_at
-- - person_name, story, highlight_type, mentioned_user_id
--
-- CAMPOS QUE NÃO EXISTEM (calculados):
-- - likes_count → SELECT COUNT(*) FROM likes
-- - comments_count → SELECT COUNT(*) FROM comments
-- - user_has_liked → EXISTS(SELECT 1 FROM likes...)
--
-- MUDANÇAS:
-- 1. created_at: TIMESTAMP → TIMESTAMPTZ (tipo real)
-- 2. likes_count: Calculado via subquery
-- 3. comments_count: Calculado via subquery
-- 4. photo_url: Corrigido (era image_url)
-- 5. Alias cm em community_members
-- 6. p_user_id qualificado com nome da função
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Função get_community_feed FINAL';
    RAISE NOTICE '📝 Todos os campos corrigidos';
    RAISE NOTICE '📝 likes_count e comments_count calculados';
END $$;

