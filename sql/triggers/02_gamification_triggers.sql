-- ============================================================================
-- GAMIFICATION TRIGGERS - Sistema de Gamificação
-- ============================================================================
-- Triggers responsáveis por verificar e conceder badges automaticamente
-- Função: auto_check_badges_with_bonus_after_action()
-- ============================================================================

-- ============================================================================
-- POSTS - Auto Badge Check
-- ============================================================================
-- Verifica badges após criação de posts (holofotes)
CREATE TRIGGER auto_badge_check_bonus_posts 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- COMMENTS - Auto Badge Check
-- ============================================================================
-- Verifica badges após criação de comentários
CREATE TRIGGER auto_badge_check_bonus_comments 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- REACTIONS - Auto Badge Check
-- ============================================================================
-- Verifica badges após criação de reações
CREATE TRIGGER auto_badge_check_bonus_reactions 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- FEEDBACKS - Auto Badge Check
-- ============================================================================
-- Verifica badges após criação de feedbacks
CREATE TRIGGER auto_badge_check_bonus_feedbacks 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- USER_POINTS - Auto Badge Check
-- ============================================================================
-- Verifica badges após atualização de pontos (level up, etc.)
CREATE TRIGGER auto_badge_check_bonus_user_points 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- ============================================================================
-- NOTAS SOBRE TRIGGERS DE GAMIFICAÇÃO
-- ============================================================================
-- 
-- Função Utilizada: auto_check_badges_with_bonus_after_action()
-- - Tipo: SECURITY INVOKER
-- - Execução: AFTER INSERT/UPDATE
-- - Propósito: Verificação automática de conquista de badges
-- 
-- Lógica do Sistema:
-- 1. Usuário realiza ação (post, comment, reaction, feedback)
-- 2. Trigger dispara verificação de badges
-- 3. Sistema verifica se usuário atingiu critérios para novos badges
-- 4. Badges são concedidos automaticamente se critérios atendidos
-- 5. Notificações são criadas para novos badges
-- 
-- Ações Monitoradas:
-- - Criação de posts (holofotes)
-- - Criação de comentários
-- - Criação de reações
-- - Criação de feedbacks
-- - Atualização de pontos (level up)
-- 
-- Sistema de Bonus:
-- - Função inclui sistema de bonus por streaks
-- - Bonus aplicados baseados em atividade consecutiva
-- - Multiplicadores por tipo de ação
-- 
-- ============================================================================

