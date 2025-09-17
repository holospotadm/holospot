-- ============================================================================
-- PUBLIC READ POLICIES - Políticas de Leitura Pública
-- ============================================================================
-- Policies que permitem leitura pública de dados (SELECT para todos)
-- Dados que devem ser visíveis para todos os usuários
-- ============================================================================

-- ============================================================================
-- BADGES - Leitura Pública
-- ============================================================================

-- Badges são públicos para todos verem
CREATE POLICY "Badges são públicos" ON public.badges
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- LEVELS - Leitura Pública  
-- ============================================================================

-- Níveis são públicos para todos verem
CREATE POLICY "Níveis são públicos" ON public.levels
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- POSTS - Leitura Pública
-- ============================================================================

-- Posts são visíveis para todos (holofotes públicos)
CREATE POLICY "Posts são visíveis para todos" ON public.posts
    FOR SELECT TO public
    USING (true);

-- Policy adicional para posts (redundante)
CREATE POLICY "posts_select_policy" ON public.posts
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- COMMENTS - Leitura Pública
-- ============================================================================

-- Comentários são visíveis para todos
CREATE POLICY "Enable read access for all users" ON public.comments
    FOR SELECT TO public
    USING (true);

-- Policy adicional para comments (redundante)
CREATE POLICY "comments_select_policy" ON public.comments
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- FEEDBACKS - Leitura Pública
-- ============================================================================

-- Feedbacks são visíveis para todos
CREATE POLICY "Enable read access for all users" ON public.feedbacks
    FOR SELECT TO public
    USING (true);

-- Policy adicional para feedbacks (redundante)
CREATE POLICY "feedbacks_select_policy" ON public.feedbacks
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- REACTIONS - Leitura Pública
-- ============================================================================

-- Reações são visíveis para todos
CREATE POLICY "Reações são visíveis para todos" ON public.reactions
    FOR SELECT TO public
    USING (true);

-- Policy adicional para reactions (redundante)
CREATE POLICY "reactions_select_policy" ON public.reactions
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- FOLLOWS - Leitura Pública
-- ============================================================================

-- Relacionamentos de follow são visíveis para todos
CREATE POLICY "Follows são visíveis para todos" ON public.follows
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- PROFILES - Leitura Pública
-- ============================================================================

-- Perfis são visíveis para todos
CREATE POLICY "Users can view all profiles" ON public.profiles
    FOR SELECT TO public
    USING (true);

-- Policy adicional para profiles (redundante)
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- USER_BADGES - Leitura Pública
-- ============================================================================

-- Badges de usuários são públicos para ranking/exibição
CREATE POLICY "Badges de usuários são públicos para leitura" ON public.user_badges
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- USER_POINTS - Leitura Pública
-- ============================================================================

-- Pontos são públicos para ranking
CREATE POLICY "Pontos são públicos para ranking" ON public.user_points
    FOR SELECT TO public
    USING (true);

-- Policy adicional para user_points (redundante)
CREATE POLICY "user_points_select_policy" ON public.user_points
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- POINTS_HISTORY - Leitura Pública (Limitada)
-- ============================================================================

-- Histórico de pontos público (para transparência)
CREATE POLICY "points_history_select_policy" ON public.points_history
    FOR SELECT TO public
    USING (true);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON POLICY "Badges são públicos" ON public.badges IS 
'Permite que todos os usuários vejam a lista de badges disponíveis no sistema';

COMMENT ON POLICY "Níveis são públicos" ON public.levels IS 
'Permite que todos os usuários vejam os níveis de progressão disponíveis';

COMMENT ON POLICY "Posts são visíveis para todos" ON public.posts IS 
'Holofotes são públicos por natureza - todos podem ver reconhecimentos';

COMMENT ON POLICY "Follows são visíveis para todos" ON public.follows IS 
'Relacionamentos de follow são públicos para construir rede social';

COMMENT ON POLICY "Pontos são públicos para ranking" ON public.user_points IS 
'Pontos são públicos para permitir rankings e competição saudável';

-- ============================================================================
-- NOTAS SOBRE POLICIES DE LEITURA PÚBLICA
-- ============================================================================
-- 
-- Filosofia de Transparência:
-- - HoloSpot é uma plataforma de reconhecimento público
-- - Holofotes (posts) devem ser visíveis para todos
-- - Rankings e conquistas são públicos para motivação
-- - Perfis são públicos para construir comunidade
-- 
-- Dados Públicos:
-- - badges: Lista de conquistas disponíveis
-- - levels: Níveis de progressão do sistema
-- - posts: Holofotes e reconhecimentos
-- - comments: Comentários em posts
-- - feedbacks: Feedbacks dados
-- - reactions: Reações em posts
-- - follows: Relacionamentos sociais
-- - profiles: Perfis de usuários
-- - user_badges: Conquistas dos usuários
-- - user_points: Pontuação para rankings
-- - points_history: Histórico para transparência
-- 
-- Policies Redundantes:
-- - Algumas tabelas têm múltiplas policies para SELECT
-- - Isso pode ser resultado de migrações ou testes
-- - Recomenda-se consolidar policies duplicadas
-- 
-- Segurança:
-- - Leitura pública não compromete dados sensíveis
-- - Usuários não podem ver dados privados de outros
-- - Sistema baseado em transparência e gamificação
-- 
-- Performance:
-- - Policies simples (true) têm performance otimizada
-- - Não há consultas complexas para leitura pública
-- - Cache pode ser aplicado facilmente
-- 
-- ============================================================================

