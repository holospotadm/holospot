-- ============================================================================
-- FIX: Adicionar chain_id na função get_community_feed
-- ============================================================================
-- PROBLEMA: Função não retorna chain_id, então badge não aparece nos posts de comunidades
-- SOLUÇÃO: Adicionar chain_id no RETURNS TABLE e no SELECT
-- ============================================================================

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
    person_name TEXT,
    mentioned_user_id UUID,
    content TEXT,
    story TEXT,
    photo_url TEXT,
    type TEXT,
    highlight_type TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    community_id UUID,
    author_name TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    author_email TEXT,
    chain_id UUID  -- ✅ ADICIONADO
)
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
    
    -- Retornar posts da comunidade com dados do autor
    RETURN QUERY
    SELECT 
        p.id, p.user_id, p.celebrated_person_name, p.person_name,
        p.mentioned_user_id, p.content, p.story, p.photo_url,
        p.type, p.highlight_type, p.created_at, p.updated_at,
        p.community_id,
        prof.name AS author_name,
        prof.username::TEXT AS author_username,
        prof.avatar_url AS author_avatar_url,
        prof.email AS author_email,
        p.chain_id  -- ✅ ADICIONADO
    FROM posts p
    LEFT JOIN profiles prof ON prof.id = p.user_id
    WHERE p.community_id = get_community_feed.p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$;

COMMENT ON FUNCTION public.get_community_feed IS 
'Retorna posts de uma comunidade (apenas membros) com dados do autor (ATUALIZADO: inclui chain_id)';

-- ✅ Função atualizada com chain_id
