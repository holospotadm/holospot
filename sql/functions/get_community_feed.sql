-- ============================================
-- FUNÇÃO: get_community_feed
-- Descrição: Retorna feed de posts da comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE OR REPLACE FUNCTION get_community_feed(
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
AS $$
BEGIN
    -- Verificar se usuário é membro
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = p_user_id 
        AND is_active = true
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
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = p_user_id) as user_has_liked
    FROM posts p
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Comentário
COMMENT ON FUNCTION get_community_feed IS 'Retorna feed de posts de uma comunidade (apenas membros)';

