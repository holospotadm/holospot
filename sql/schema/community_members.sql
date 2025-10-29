-- ============================================
-- TABELA: community_members
-- Descrição: Armazena membros das comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE TABLE IF NOT EXISTS community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(community_id, user_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_community_members_community ON community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user ON community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_members_active ON community_members(community_id, is_active) WHERE is_active = true;

-- Comentários
COMMENT ON TABLE community_members IS 'Membros das comunidades';
COMMENT ON COLUMN community_members.id IS 'ID único do membro';
COMMENT ON COLUMN community_members.community_id IS 'ID da comunidade';
COMMENT ON COLUMN community_members.user_id IS 'ID do usuário';
COMMENT ON COLUMN community_members.role IS 'Papel do membro (owner, member)';
COMMENT ON COLUMN community_members.joined_at IS 'Data de entrada na comunidade';
COMMENT ON COLUMN community_members.is_active IS 'Se o membro está ativo';

