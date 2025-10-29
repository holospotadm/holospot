-- ============================================
-- RLS POLICIES: communities
-- Descrição: Políticas de segurança para comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Habilitar RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;

-- Drop políticas existentes (se houver)
DROP POLICY IF EXISTS "Members can view community" ON communities;
DROP POLICY IF EXISTS "Only community owners can create communities" ON communities;
DROP POLICY IF EXISTS "Owner can update community" ON communities;
DROP POLICY IF EXISTS "Owner can delete community" ON communities;

-- Política: Membros podem ver comunidades que participam
CREATE POLICY "Members can view community"
ON communities FOR SELECT
USING (
    id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Política: Apenas community_owner pode criar
CREATE POLICY "Only community owners can create communities"
ON communities FOR INSERT
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM profiles WHERE community_owner = true
    )
);

-- Política: Owner pode atualizar sua comunidade
CREATE POLICY "Owner can update community"
ON communities FOR UPDATE
USING (auth.uid() = owner_id);

-- Política: Owner pode deletar sua comunidade
CREATE POLICY "Owner can delete community"
ON communities FOR DELETE
USING (auth.uid() = owner_id);

