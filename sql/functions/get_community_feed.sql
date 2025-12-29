-- ============================================================================
-- FUNÇÃO: get_community_feed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_community_feed(p_community_id uuid, p_user_id uuid, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, user_id uuid, celebrated_person_name text, person_name text, mentioned_user_id uuid, content text, story text, photo_url text, type text, highlight_type text, created_at timestamp with time zone, updated_at timestamp with time zone, community_id uuid, author_name text, author_username text, author_avatar_url text, author_email text, chain_id uuid)
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
$function$

