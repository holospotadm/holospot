-- ============================================
-- RLS POLICIES UPDATE: posts
-- Descrição: Atualiza políticas para suportar comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Drop políticas antigas
DROP POLICY IF EXISTS "Users can view posts" ON posts;
DROP POLICY IF EXISTS "Users can create posts" ON posts;
DROP POLICY IF EXISTS "Owner can delete community posts" ON posts;
DROP POLICY IF EXISTS "Owner can update community posts" ON posts;

-- Política: Usuários podem ver posts globais ou de comunidades que participam
CREATE POLICY "Users can view posts"
ON posts FOR SELECT
USING (
    community_id IS NULL OR -- posts globais
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Política: Usuários podem criar posts globais ou em comunidades que participam
CREATE POLICY "Users can create posts"
ON posts FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND (
        community_id IS NULL OR -- posts globais
        community_id IN (
            SELECT community_id FROM community_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    )
);

-- Política: Owner pode deletar posts da comunidade (além do próprio post)
CREATE POLICY "Owner can delete community posts"
ON posts FOR DELETE
USING (
    auth.uid() = user_id OR -- próprio post
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);

-- Política: Owner pode editar posts da comunidade (moderação)
CREATE POLICY "Owner can update community posts"
ON posts FOR UPDATE
USING (
    auth.uid() = user_id OR -- próprio post
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);

