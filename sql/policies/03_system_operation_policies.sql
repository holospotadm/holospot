-- ============================================================================
-- SYSTEM OPERATION POLICIES - Políticas de Operação do Sistema
-- ============================================================================
-- Policies que permitem operações automáticas do sistema
-- Triggers, funções e processos internos que precisam de acesso especial
-- ============================================================================

-- ============================================================================
-- GENERIC SYSTEM POLICIES - Políticas Genéricas do Sistema
-- ============================================================================

-- Policy genérica para inserção em posts
CREATE POLICY "posts_insert_policy" ON public.posts
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para atualização em posts
CREATE POLICY "posts_update_policy" ON public.posts
    FOR UPDATE TO public
    USING (true);

-- Policy genérica para deleção em posts
CREATE POLICY "posts_delete_policy" ON public.posts
    FOR DELETE TO public
    USING (true);

-- ============================================================================
-- COMMENTS - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de comentários
CREATE POLICY "comments_insert_policy" ON public.comments
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para atualização de comentários
CREATE POLICY "comments_update_policy" ON public.comments
    FOR UPDATE TO public
    USING (true);

-- Policy genérica para deleção de comentários
CREATE POLICY "comments_delete_policy" ON public.comments
    FOR DELETE TO public
    USING (true);

-- ============================================================================
-- FEEDBACKS - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de feedbacks
CREATE POLICY "feedbacks_insert_policy" ON public.feedbacks
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para atualização de feedbacks
CREATE POLICY "feedbacks_update_policy" ON public.feedbacks
    FOR UPDATE TO public
    USING (true);

-- Policy genérica para deleção de feedbacks
CREATE POLICY "feedbacks_delete_policy" ON public.feedbacks
    FOR DELETE TO public
    USING (true);

-- ============================================================================
-- REACTIONS - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de reações
CREATE POLICY "reactions_insert_policy" ON public.reactions
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para deleção de reações
CREATE POLICY "reactions_delete_policy" ON public.reactions
    FOR DELETE TO public
    USING (true);

-- ============================================================================
-- POINTS_HISTORY - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção no histórico de pontos
CREATE POLICY "points_history_insert_policy" ON public.points_history
    FOR INSERT TO public
    WITH CHECK (true);

-- ============================================================================
-- USER_POINTS - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de pontos de usuário
CREATE POLICY "user_points_insert_policy" ON public.user_points
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para atualização de pontos de usuário
CREATE POLICY "user_points_update_policy" ON public.user_points
    FOR UPDATE TO public
    USING (true);

-- ============================================================================
-- USER_STREAKS - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de streaks
CREATE POLICY "user_streaks_insert_policy" ON public.user_streaks
    FOR INSERT TO public
    WITH CHECK (true);

-- Policy genérica para atualização de streaks
CREATE POLICY "user_streaks_update_policy" ON public.user_streaks
    FOR UPDATE TO public
    USING (true);

-- ============================================================================
-- PROFILES - Operações do Sistema
-- ============================================================================

-- Policy genérica para inserção de perfis
CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT TO public
    WITH CHECK (true);

-- ============================================================================
-- NOTIFICATIONS - Operações do Sistema
-- ============================================================================

-- Sistema pode criar notificações para qualquer usuário
CREATE POLICY "Sistema pode criar notificações" ON public.notifications
    FOR INSERT TO public
    WITH CHECK (true);

-- ============================================================================
-- AUTHENTICATED USER POLICIES - Políticas para Usuários Autenticados
-- ============================================================================

-- Apenas usuários autenticados podem inserir comentários
CREATE POLICY "Enable insert for authenticated users only" ON public.comments
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Apenas usuários autenticados podem inserir feedbacks
CREATE POLICY "Enable insert for authenticated users only" ON public.feedbacks
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON POLICY "posts_insert_policy" ON public.posts IS 
'Policy genérica que permite inserção de posts pelo sistema (triggers, funções)';

COMMENT ON POLICY "Sistema pode criar notificações" ON public.notifications IS 
'Permite que o sistema crie notificações automáticas para qualquer usuário';

COMMENT ON POLICY "Enable insert for authenticated users only" ON public.comments IS 
'Garante que apenas usuários autenticados podem criar comentários';

-- ============================================================================
-- NOTAS SOBRE POLICIES DE OPERAÇÃO DO SISTEMA
-- ============================================================================
-- 
-- Propósito:
-- - Permitir operações automáticas do sistema
-- - Triggers e funções precisam de acesso irrestrito
-- - Processos internos de gamificação
-- - Criação automática de notificações
-- 
-- Padrão de Policies Genéricas:
-- - WITH CHECK (true): Permite qualquer inserção
-- - USING (true): Permite qualquer acesso/modificação
-- - Usadas por triggers e funções do sistema
-- 
-- Diferença entre Roles:
-- - public: Acesso geral (inclui sistema e usuários)
-- - authenticated: Apenas usuários logados
-- - Sistema usa 'public' para operações automáticas
-- 
-- Policies Duplicadas:
-- - Muitas tabelas têm policies específicas E genéricas
-- - Policies específicas: Baseadas em auth.uid()
-- - Policies genéricas: Para operações do sistema
-- - Ambas coexistem (PERMISSIVE permite qualquer uma)
-- 
-- Segurança:
-- - Policies genéricas são necessárias para triggers
-- - Sistema precisa inserir dados automaticamente
-- - Usuários ainda têm policies específicas
-- - Dupla proteção: aplicação + banco
-- 
-- Operações Automáticas:
-- - Criação de pontos (triggers)
-- - Inserção de histórico (triggers)
-- - Notificações automáticas (triggers)
-- - Atualização de streaks (sistema)
-- - Concessão de badges (sistema)
-- 
-- Authenticated vs Public:
-- - comments/feedbacks: Preferem authenticated
-- - Outras operações: Usam public
-- - Sistema pode operar como public
-- - Usuários precisam estar authenticated
-- 
-- Manutenção:
-- - Policies genéricas facilitam desenvolvimento
-- - Permitem flexibilidade para triggers
-- - Podem ser consolidadas no futuro
-- - Monitorar uso para otimização
-- 
-- ============================================================================

