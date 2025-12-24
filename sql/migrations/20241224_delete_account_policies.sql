-- =====================================================
-- POLÍTICAS PARA DELETAR CONTA - HoloSpot
-- Migração: 20241224_delete_account_policies.sql
-- =====================================================

-- Permitir que usuários atualizem correntes para anonimizar
-- (setar created_by como NULL quando deletam conta)
CREATE POLICY IF NOT EXISTS "Users can anonymize their chains" ON chains
    FOR UPDATE
    TO authenticated
    USING (created_by = auth.uid())
    WITH CHECK (created_by IS NULL OR created_by = auth.uid());

-- Permitir que usuários atualizem participações em correntes para anonimizar
CREATE POLICY IF NOT EXISTS "Users can anonymize their chain participations" ON chain_participations
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Permitir que usuários deletem seus próprios feedbacks
CREATE POLICY IF NOT EXISTS "Users can delete own feedbacks" ON feedbacks
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- Permitir que usuários deletem seus próprios comentários
CREATE POLICY IF NOT EXISTS "Users can delete own comments" ON comments
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- Permitir que usuários deletem suas próprias notificações (enviadas ou recebidas)
CREATE POLICY IF NOT EXISTS "Users can delete own notifications" ON notifications
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid() OR from_user_id = auth.uid());

-- Permitir que usuários deletem seus próprios follows
CREATE POLICY IF NOT EXISTS "Users can delete own follows" ON follows
    FOR DELETE
    TO authenticated
    USING (follower_id = auth.uid() OR following_id = auth.uid());

-- Permitir que usuários deletem suas próprias mensagens
CREATE POLICY IF NOT EXISTS "Users can delete own messages" ON messages
    FOR DELETE
    TO authenticated
    USING (sender_id = auth.uid());

-- Permitir que usuários deletem suas participações em comunidades
CREATE POLICY IF NOT EXISTS "Users can delete own community memberships" ON community_members
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- Permitir que usuários deletem seus próprios posts
CREATE POLICY IF NOT EXISTS "Users can delete own posts" ON posts
    FOR DELETE
    TO authenticated
    USING (user_id = auth.uid());

-- Permitir que usuários deletem seu próprio perfil
CREATE POLICY IF NOT EXISTS "Users can delete own profile" ON profiles
    FOR DELETE
    TO authenticated
    USING (id = auth.uid());

-- =====================================================
-- COMENTÁRIOS
-- =====================================================

COMMENT ON POLICY "Users can anonymize their chains" ON chains IS 'Permite que usuários anonimizem correntes ao deletar conta';
COMMENT ON POLICY "Users can anonymize their chain participations" ON chain_participations IS 'Permite que usuários anonimizem participações ao deletar conta';
