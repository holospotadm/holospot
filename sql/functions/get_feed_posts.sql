-- ============================================================================
-- FUNÇÃO: get_feed_posts
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_feed_posts(p_user_id uuid, p_filter_type text DEFAULT 'all'::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, user_id uuid, celebrated_person_name text, person_name text, mentioned_user_id uuid, content text, story text, photo_url text, type text, highlight_type text, created_at timestamp with time zone, updated_at timestamp with time zone, author_name text, author_username text, author_avatar_url text, author_email text, chain_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    CASE p_filter_type
        WHEN 'all' THEN
            -- Todos os posts públicos (excluir posts de comunidades)
            RETURN QUERY
            SELECT 
                p.id, p.user_id, p.celebrated_person_name, p.person_name,
                p.mentioned_user_id, p.content, p.story, p.photo_url,
                p.type, p.highlight_type, p.created_at, p.updated_at,
                -- Dados do autor (com CAST para TEXT)
                prof.name AS author_name,
                prof.username::TEXT AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email,
                p.chain_id  -- ✅ ADICIONADO
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
                -- Dados do autor (com CAST para TEXT)
                prof.name AS author_name,
                prof.username::TEXT AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email,
                p.chain_id  -- ✅ ADICIONADO
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
                -- Dados do autor (com CAST para TEXT)
                prof.name AS author_name,
                prof.username::TEXT AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email,
                p.chain_id  -- ✅ ADICIONADO
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
                -- Dados do autor (com CAST para TEXT)
                prof.name AS author_name,
                prof.username::TEXT AS author_username,
                prof.avatar_url AS author_avatar_url,
                prof.email AS author_email,
                p.chain_id  -- ✅ ADICIONADO
            FROM posts p
            LEFT JOIN profiles prof ON prof.id = p.user_id
            WHERE p.community_id IS NULL
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
    END CASE;
END;
$function$

