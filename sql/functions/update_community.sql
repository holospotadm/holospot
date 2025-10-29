-- ============================================
-- FUNÇÃO: update_community
-- Descrição: Atualiza informações da comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE OR REPLACE FUNCTION update_community(
    p_community_id UUID,
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_logo_url TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se usuário é owner
    IF NOT EXISTS (
        SELECT 1 FROM communities 
        WHERE id = p_community_id 
        AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can update community';
    END IF;
    
    -- Atualizar comunidade
    UPDATE communities
    SET 
        name = p_name,
        slug = p_slug,
        description = p_description,
        emoji = COALESCE(p_emoji, emoji),
        logo_url = p_logo_url,
        updated_at = NOW()
    WHERE id = p_community_id;
    
    RETURN true;
END;
$$;

-- Comentário
COMMENT ON FUNCTION update_community IS 'Atualiza informações de uma comunidade (apenas owner)';

