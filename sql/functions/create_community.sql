-- ============================================
-- FUNÇÃO: create_community
-- Descrição: Cria uma nova comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE OR REPLACE FUNCTION create_community(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_community_id UUID;
    v_is_community_owner BOOLEAN;
BEGIN
    -- Verificar se usuário está autenticado
    IF auth.uid() != p_owner_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Verificar se usuário é community_owner
    SELECT community_owner INTO v_is_community_owner
    FROM profiles
    WHERE id = p_owner_id;
    
    IF NOT v_is_community_owner THEN
        RAISE EXCEPTION 'User is not authorized to create communities';
    END IF;
    
    -- Criar comunidade
    INSERT INTO communities (name, slug, description, emoji, owner_id)
    VALUES (p_name, p_slug, p_description, COALESCE(p_emoji, '🏢'), p_owner_id)
    RETURNING id INTO v_community_id;
    
    -- Adicionar owner como membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (v_community_id, p_owner_id, 'owner');
    
    -- Atribuir badge "Owner de Comunidade"
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_owner_id,
        'Owner de Comunidade',
        'Criou uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN v_community_id;
END;
$$;

-- Comentário
COMMENT ON FUNCTION create_community IS 'Cria uma nova comunidade e adiciona o owner como membro';

