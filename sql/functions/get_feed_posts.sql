-- Função para buscar posts do feed com filtros
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
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    CASE p_filter_type
        WHEN 'all' THEN
            -- Todos os posts, ordenados por data
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'following' THEN
            -- Apenas posts de quem o usuário segue
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            INNER JOIN follows f ON f.following_id = p.user_id
            WHERE f.follower_id = p_user_id
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'recommended' THEN
            -- Por enquanto, mesmo que 'all' (preparado para algoritmo futuro)
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        ELSE
            -- Fallback: todos os posts
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
    END CASE;
END;
$$;

COMMENT ON FUNCTION public.get_feed_posts IS 
'Busca posts do feed com filtros: all (todos), following (apenas quem segue), recommended (recomendados)';

