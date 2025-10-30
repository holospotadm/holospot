-- ============================================
-- MIGRATION: Adicionar dados do autor em get_community_feed
-- Data: 2024-10-29
-- Descrição: Adiciona JOIN com profiles para retornar dados do autor
--            (name, username, avatar_url, email) nos posts de comunidades
-- ============================================

-- PASSO 1: Remover função antiga
DROP FUNCTION IF EXISTS public.get_community_feed(uuid, uuid, integer, integer);

-- PASSO 2: Criar função nova com dados do autor
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
    -- Dados do autor (NOVOS CAMPOS)
    author_name TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    author_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
        -- Dados do autor (com CAST para TEXT)
        prof.name AS author_name,
        prof.username::TEXT AS author_username,
        prof.avatar_url AS author_avatar_url,
        prof.email AS author_email
    FROM posts p
    LEFT JOIN profiles prof ON prof.id = p.user_id
    WHERE p.community_id = get_community_feed.p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_community_feed IS 
'Retorna posts de uma comunidade (apenas membros) com dados do autor';

