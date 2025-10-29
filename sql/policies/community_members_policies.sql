-- ============================================
-- RLS POLICIES: community_members
-- Descrição: Políticas de segurança para membros
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Habilitar RLS
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

-- Drop políticas existentes (se houver)
DROP POLICY IF EXISTS "Members can view other members" ON community_members;
DROP POLICY IF EXISTS "Owner can add members" ON community_members;
DROP POLICY IF EXISTS "Owner can update members" ON community_members;
DROP POLICY IF EXISTS "Owner can remove members" ON community_members;

-- Política: Membros podem ver outros membros da mesma comunidade
CREATE POLICY "Members can view other members"
ON community_members FOR SELECT
USING (
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Política: Owner pode adicionar membros
CREATE POLICY "Owner can add members"
ON community_members FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = community_members.community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
    )
);

-- Política: Owner pode atualizar membros
CREATE POLICY "Owner can update members"
ON community_members FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);

-- Política: Owner pode remover membros
CREATE POLICY "Owner can remove members"
ON community_members FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);

