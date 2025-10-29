-- ============================================
-- FUNÇÃO: remove_community_member
-- Descrição: Remove um membro da comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE OR REPLACE FUNCTION remove_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se quem está removendo é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can remove members';
    END IF;
    
    -- Não pode remover o próprio owner
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Owner cannot remove themselves';
    END IF;
    
    -- Remover membro (soft delete)
    UPDATE community_members
    SET is_active = false
    WHERE community_id = p_community_id AND user_id = p_user_id;
    
    RETURN true;
END;
$$;

-- Comentário
COMMENT ON FUNCTION remove_community_member IS 'Remove um membro da comunidade (apenas owner)';

