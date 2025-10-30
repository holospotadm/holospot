-- ============================================
-- MIGRATION: Isolar posts de comunidades + Adicionar dados do autor
-- Data: 2024-10-29
-- Descrição: 
--   1. Adiciona filtro community_id IS NULL em get_feed_posts
--      para que posts de comunidades apareçam APENAS no feed da comunidade
--   2. Adiciona JOIN com profiles para retornar dados do autor (name, username, avatar_url)
--      para corrigir o problema de @usuario em vez de @username.real
-- ============================================

CREATE OR REPLACE FUNCTION public.get_feed_posts(
    p_user_id UUID,
    p_filter_type TEXT DEFAULT 'all',
    p_limit INTEGER DEFAULT 50,
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
    -- Dados do autor
    author_name TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    author_email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    CASE p_filter_type
        WHEN 'all' THEN
            -- Todos os posts públicos (excluir posts de comunidades)
            RETURN QUERY
            SELECT 
                p.id, p.user_id, p.celebrated_person_name, p.person_name,
                p.mentioned_user_id, p.content, p.story, p.photo_url,
                p.type, p.highlight_type, p.created_at, p.updated_at,
                -- Dados do autor
                prof.name AS author_name,
                prof.username AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'following' THEN
            -- Apenas posts públicos de quem o usuário segue (excluir posts de comunidades)
            RETURN QUERY
            SELECT 
                p.id, p.user_id, p.celebrated_person_name, p.person_name,
                p.mentioned_user_id, p.content, p.story, p.photo_url,
                p.type, p.highlight_type, p.created_at, p.updated_at,
                -- Dados do autor
                prof.name AS author_name,
                prof.username AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            INNER JOIN follows f ON f.following_id = p.user_id
            WHERE f.follower_id = p_user_id
              AND p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'recommended' THEN
            -- Posts públicos recomendados (excluir posts de comunidades)
            RETURN QUERY
            SELECT 
                p.id, p.user_id, p.celebrated_person_name, p.person_name,
                p.mentioned_user_id, p.content, p.story, p.photo_url,
                p.type, p.highlight_type, p.created_at, p.updated_at,
                -- Dados do autor
                prof.name AS author_name,
                prof.username AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        ELSE
            -- Fallback: todos os posts públicos (excluir posts de comunidades)
            RETURN QUERY
            SELECT 
                p.id, p.user_id, p.celebrated_person_name, p.person_name,
                p.mentioned_user_id, p.content, p.story, p.photo_url,
                p.type, p.highlight_type, p.created_at, p.updated_at,
                -- Dados do autor
                prof.name AS author_name,
                prof.username AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
    END CASE;
END;
$$;

COMMENT ON FUNCTION public.get_feed_posts IS 
'Retorna posts para o feed público (excluindo posts de comunidades) com dados do autor';

