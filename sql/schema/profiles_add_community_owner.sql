-- ============================================
-- MODIFICAÇÃO: profiles
-- Descrição: Adiciona campo community_owner
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Adicionar campo community_owner
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS community_owner BOOLEAN DEFAULT false;

-- Criar índice
CREATE INDEX IF NOT EXISTS idx_profiles_community_owner ON profiles(community_owner) WHERE community_owner = true;

-- Comentário
COMMENT ON COLUMN profiles.community_owner IS 'Se o usuário pode criar comunidades';

-- Habilitar para @guilherme.dutra
UPDATE profiles 
SET community_owner = true 
WHERE username = 'guilherme.dutra';

