-- ============================================
-- FUNÇÃO: add_community_member
-- Descrição: Adiciona um membro à comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE OR REPLACE FUNCTION add_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se quem está adicionando é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can add members';
    END IF;
    
    -- Adicionar membro (ou reativar se já existir)
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, 'member')
    ON CONFLICT (community_id, user_id) DO UPDATE
    SET is_active = true;
    
    -- Atribuir badge "Membro de Comunidade"
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_user_id,
        'Membro de Comunidade',
        'Entrou em uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN true;
END;
$$;

-- Comentário
COMMENT ON FUNCTION add_community_member IS 'Adiciona um membro à comunidade (apenas owner)';

