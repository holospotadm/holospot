-- ============================================
-- TABELA: communities
-- Descrição: Armazena informações das comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    emoji TEXT DEFAULT '🏢',
    logo_url TEXT,
    owner_id UUID REFERENCES profiles(id) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_communities_owner ON communities(owner_id);
CREATE INDEX IF NOT EXISTS idx_communities_slug ON communities(slug);
CREATE INDEX IF NOT EXISTS idx_communities_active ON communities(is_active) WHERE is_active = true;

-- Comentários
COMMENT ON TABLE communities IS 'Comunidades privadas do HoloSpot';
COMMENT ON COLUMN communities.id IS 'ID único da comunidade';
COMMENT ON COLUMN communities.name IS 'Nome da comunidade';
COMMENT ON COLUMN communities.slug IS 'URL amigável (único e obrigatório)';
COMMENT ON COLUMN communities.description IS 'Descrição da comunidade';
COMMENT ON COLUMN communities.emoji IS 'Emoji que representa a comunidade';
COMMENT ON COLUMN communities.logo_url IS 'URL do logo da comunidade';
COMMENT ON COLUMN communities.owner_id IS 'ID do dono da comunidade';
COMMENT ON COLUMN communities.created_at IS 'Data de criação';
COMMENT ON COLUMN communities.updated_at IS 'Data da última atualização';
COMMENT ON COLUMN communities.is_active IS 'Se a comunidade está ativa';

