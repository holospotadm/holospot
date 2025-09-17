-- ============================================================================
-- SECURITY TRIGGERS - Sistema de Segurança e Integridade
-- ============================================================================
-- Triggers responsáveis por manter integridade de dados e aplicar regras de negócio
-- Funções especializadas para operações seguras
-- ============================================================================

-- ============================================================================
-- POSTS - Secure Insert
-- ============================================================================
-- Aplica regras de negócio e validações na criação de posts
CREATE TRIGGER post_insert_secure_trigger 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_post_insert_secure();

-- ============================================================================
-- COMMENTS - Secure Operations
-- ============================================================================
-- Aplica regras de negócio na criação de comentários
CREATE TRIGGER comment_insert_secure_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_insert_secure();

-- Aplica regras de negócio na deleção de comentários
CREATE TRIGGER comment_delete_secure_trigger 
    AFTER DELETE ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_delete_secure();

-- ============================================================================
-- REACTIONS - Secure Operations
-- ============================================================================
-- Aplica regras de negócio na criação de reações
CREATE TRIGGER reaction_insert_secure_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_insert_secure();

-- Aplica regras de negócio na deleção de reações
CREATE TRIGGER reaction_delete_secure_trigger 
    AFTER DELETE ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_delete_secure();

-- ============================================================================
-- REACTIONS - Points Management
-- ============================================================================
-- Gerencia pontos de forma segura para reações
CREATE TRIGGER reaction_points_simple_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_points_simple();

-- ============================================================================
-- FEEDBACKS - Secure Insert
-- ============================================================================
-- Aplica regras de negócio na criação de feedbacks
CREATE TRIGGER feedback_insert_secure_trigger 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_feedback_insert_secure();

-- ============================================================================
-- NOTAS SOBRE TRIGGERS DE SEGURANÇA
-- ============================================================================
-- 
-- Funções Utilizadas:
-- - handle_post_insert_secure(): Validações e regras para posts
-- - handle_comment_insert_secure(): Validações e regras para comentários
-- - handle_comment_delete_secure(): Limpeza segura ao deletar comentários
-- - handle_reaction_insert_secure(): Validações e regras para reações
-- - handle_reaction_delete_secure(): Limpeza segura ao deletar reações
-- - handle_reaction_points_simple(): Gerenciamento seguro de pontos
-- - handle_feedback_insert_secure(): Validações e regras para feedbacks
-- 
-- Todas as funções: SECURITY INVOKER
-- 
-- Responsabilidades dos Triggers de Segurança:
-- 
-- 1. VALIDAÇÃO DE DADOS:
--    - Verificar integridade referencial
--    - Validar regras de negócio
--    - Prevenir dados inconsistentes
-- 
-- 2. GERENCIAMENTO DE PONTOS:
--    - Calcular pontos por ação
--    - Atualizar totais de usuários
--    - Manter histórico de pontuação
--    - Aplicar multiplicadores e bonus
-- 
-- 3. CONTROLE DE DUPLICATAS:
--    - Prevenir reações duplicadas
--    - Controlar spam de ações
--    - Validar unicidade onde necessário
-- 
-- 4. LIMPEZA DE DADOS:
--    - Remover dados órfãos
--    - Ajustar contadores
--    - Manter consistência referencial
-- 
-- 5. AUDITORIA DE AÇÕES:
--    - Registrar ações em points_history
--    - Manter rastreabilidade
--    - Log de operações críticas
-- 
-- Sistema de Pontos Integrado:
-- - Posts: +10 pontos para autor
-- - Comments: +2 pontos para autor
-- - Reactions: +1 ponto para quem reage, +1 para autor do post
-- - Feedbacks: +3 pontos para quem dá feedback
-- - Bonus por streaks aplicados automaticamente
-- 
-- Prevenção de Fraudes:
-- - Validação de ownership
-- - Prevenção de auto-reações
-- - Controle de rate limiting
-- - Validação de dados de entrada
-- 
-- ============================================================================

