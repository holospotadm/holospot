-- ============================================
-- MODIFICAÇÃO: posts
-- Descrição: Adiciona campo community_id
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Adicionar campo community_id
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES communities(id) ON DELETE CASCADE;

-- Criar índice
CREATE INDEX IF NOT EXISTS idx_posts_community ON posts(community_id) WHERE community_id IS NOT NULL;

-- Comentário
COMMENT ON COLUMN posts.community_id IS 'ID da comunidade (NULL = post global)';

