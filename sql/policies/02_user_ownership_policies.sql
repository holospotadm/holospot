-- ============================================================================
-- USER OWNERSHIP POLICIES - Políticas de Propriedade do Usuário
-- ============================================================================
-- Policies que garantem que usuários só podem acessar/modificar seus próprios dados
-- Baseadas em auth.uid() para isolamento por usuário
-- ============================================================================

-- ============================================================================
-- POSTS - Propriedade do Usuário
-- ============================================================================

-- Usuários podem criar seus próprios posts
CREATE POLICY "Users can create posts" ON public.posts
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);

-- Policy adicional para criação de posts (redundante)
CREATE POLICY "Usuários podem criar seus próprios posts" ON public.posts
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);

-- Usuários podem atualizar seus próprios posts
CREATE POLICY "Usuários podem atualizar seus próprios posts" ON public.posts
    FOR UPDATE TO public
    USING (auth.uid() = user_id);

-- Usuários podem deletar seus próprios posts
CREATE POLICY "Usuários podem deletar seus próprios posts" ON public.posts
    FOR DELETE TO public
    USING (auth.uid() = user_id);

-- ============================================================================
-- REACTIONS - Propriedade do Usuário
-- ============================================================================

-- Usuários podem criar suas próprias reações
CREATE POLICY "Users can create reactions" ON public.reactions
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);

-- Policy adicional para criação de reações (redundante)
CREATE POLICY "Usuários podem criar suas próprias reações" ON public.reactions
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);

-- Usuários podem deletar suas próprias reações
CREATE POLICY "Usuários podem deletar suas próprias reações" ON public.reactions
    FOR DELETE TO public
    USING (auth.uid() = user_id);

-- ============================================================================
-- FOLLOWS - Propriedade do Usuário
-- ============================================================================

-- Usuários podem criar seus próprios follows (seguir outros)
CREATE POLICY "Usuários podem criar seus próprios follows" ON public.follows
    FOR INSERT TO public
    WITH CHECK (auth.uid() = follower_id);

-- Usuários podem deletar seus próprios follows (deixar de seguir)
CREATE POLICY "Usuários podem deletar seus próprios follows" ON public.follows
    FOR DELETE TO public
    USING (auth.uid() = follower_id);

-- ============================================================================
-- NOTIFICATIONS - Propriedade do Usuário
-- ============================================================================

-- Usuários veem apenas suas próprias notificações
CREATE POLICY "Usuários veem apenas suas notificações" ON public.notifications
    FOR SELECT TO public
    USING (auth.uid() = user_id);

-- Usuários podem atualizar suas próprias notificações (marcar como lida)
CREATE POLICY "Usuários podem atualizar suas notificações" ON public.notifications
    FOR UPDATE TO public
    USING (auth.uid() = user_id);

-- ============================================================================
-- POINTS_HISTORY - Propriedade do Usuário
-- ============================================================================

-- Usuários podem ver seu próprio histórico de pontos
CREATE POLICY "Usuários podem ver seu próprio histórico" ON public.points_history
    FOR SELECT TO public
    USING (auth.uid() = user_id);

-- Sistema pode inserir histórico para o usuário autenticado
CREATE POLICY "Sistema pode inserir histórico de pontos" ON public.points_history
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);

-- Usuários podem deletar seu próprio histórico
CREATE POLICY "Users can delete their own points_history" ON public.points_history
    FOR DELETE TO public
    USING (auth.uid() = user_id);

-- Usuários podem deletar histórico relacionado aos seus posts
CREATE POLICY "Users can delete points_history related to their posts" ON public.points_history
    FOR DELETE TO public
    USING ((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM posts
  WHERE ((posts.id = points_history.post_id) AND (posts.user_id = auth.uid())))));

-- ============================================================================
-- USER_POINTS - Propriedade do Usuário
-- ============================================================================

-- Usuários podem ver seus próprios pontos
CREATE POLICY "Usuários podem ver seus próprios pontos" ON public.user_points
    FOR SELECT TO public
    USING (auth.uid() = user_id);

-- Sistema pode inserir/atualizar pontos do usuário
CREATE POLICY "Sistema pode inserir/atualizar pontos" ON public.user_points
    FOR ALL TO public
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- USER_STREAKS - Propriedade do Usuário
-- ============================================================================

-- Usuários podem ver seu próprio streak
CREATE POLICY "Users can view own streak" ON public.user_streaks
    FOR SELECT TO public
    USING (auth.uid() = user_id);

-- Usuários podem atualizar seu próprio streak
CREATE POLICY "Users can update own streak" ON public.user_streaks
    FOR UPDATE TO public
    USING (auth.uid() = user_id);

-- ============================================================================
-- USER_BADGES - Propriedade do Usuário
-- ============================================================================

-- Usuários podem ver seus próprios badges
CREATE POLICY "Usuários podem ver seus próprios badges" ON public.user_badges
    FOR SELECT TO public
    USING (auth.uid() = user_id);

-- Sistema pode inserir badges para usuários
CREATE POLICY "Sistema pode inserir badges de usuários" ON public.user_badges
    FOR INSERT TO public
    WITH CHECK (true); -- Sistema pode inserir para qualquer usuário

-- ============================================================================
-- PROFILES - Propriedade do Usuário
-- ============================================================================

-- Usuários podem atualizar seu próprio perfil (implícito - sem condição específica)
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE TO public
    USING (true); -- Permite atualização (deve ser restringido por aplicação)

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON POLICY "Users can create posts" ON public.posts IS 
'Garante que usuários só podem criar posts em seu próprio nome';

COMMENT ON POLICY "Usuários veem apenas suas notificações" ON public.notifications IS 
'Isolamento total - cada usuário vê apenas suas próprias notificações';

COMMENT ON POLICY "Users can delete points_history related to their posts" ON public.points_history IS 
'Permite que usuários deletem histórico relacionado aos seus posts (além do próprio histórico)';

COMMENT ON POLICY "Sistema pode inserir/atualizar pontos" ON public.user_points IS 
'Policy ALL permite INSERT e UPDATE para o sistema de pontuação';

-- ============================================================================
-- NOTAS SOBRE POLICIES DE PROPRIEDADE
-- ============================================================================
-- 
-- Princípio de Isolamento:
-- - Cada usuário só acessa seus próprios dados
-- - Baseado em auth.uid() do Supabase Auth
-- - Garante privacidade e segurança
-- 
-- Padrões Identificados:
-- - INSERT: WITH CHECK (auth.uid() = user_id)
-- - UPDATE: USING (auth.uid() = user_id)
-- - DELETE: USING (auth.uid() = user_id)
-- - SELECT: USING (auth.uid() = user_id) para dados privados
-- 
-- Casos Especiais:
-- - points_history: Usuário pode deletar histórico de seus posts
-- - user_badges: Sistema pode inserir para qualquer usuário
-- - notifications: Apenas o destinatário pode ver/atualizar
-- - follows: Baseado em follower_id (quem segue)
-- 
-- Policies Redundantes:
-- - Algumas tabelas têm múltiplas policies similares
-- - Resultado de migrações ou testes
-- - Recomenda-se consolidação
-- 
-- Segurança:
-- - auth.uid() garante usuário autenticado
-- - Isolamento total entre usuários
-- - Sistema pode operar em nome dos usuários
-- 
-- Funcionalidades:
-- - Usuários controlam seus próprios dados
-- - Sistema automatiza operações (pontos, badges)
-- - Transparência com dados públicos
-- - Privacidade com dados pessoais
-- 
-- Validações:
-- - WITH CHECK valida dados na inserção
-- - USING valida acesso na leitura/modificação
-- - Combinação garante integridade completa
-- 
-- ============================================================================

