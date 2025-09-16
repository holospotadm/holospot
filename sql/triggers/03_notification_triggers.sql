-- ============================================================================
-- NOTIFICATION TRIGGERS - Sistema de Notificações
-- ============================================================================
-- Triggers responsáveis por criar notificações automáticas para usuários
-- Múltiplas funções especializadas por tipo de notificação
-- ============================================================================

-- ============================================================================
-- POSTS - Holofote Notifications
-- ============================================================================
-- Cria notificação quando alguém é mencionado em um holofote
CREATE TRIGGER holofote_notification_trigger 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_holofote_notification();

-- ============================================================================
-- COMMENTS - Comment Notifications
-- ============================================================================
-- Cria notificação quando alguém comenta em um post
CREATE TRIGGER comment_notification_correto_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_notification_correto();

-- Notificação simplificada para comentários
CREATE TRIGGER comment_notify_only_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_notification_only();

-- ============================================================================
-- REACTIONS - Reaction Notifications
-- ============================================================================
-- Cria notificação quando alguém reage a um post
CREATE TRIGGER reaction_notification_simple_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_simple();

-- ============================================================================
-- FEEDBACKS - Feedback Notifications
-- ============================================================================
-- Cria notificação quando alguém dá feedback
CREATE TRIGGER feedback_notification_correto_trigger 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_feedback_notification_correto();

-- ============================================================================
-- FOLLOWS - Follow Notifications
-- ============================================================================
-- Cria notificação quando alguém segue outro usuário
CREATE TRIGGER follow_notification_correto_trigger 
    AFTER INSERT ON public.follows 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_follow_notification_correto();

-- ============================================================================
-- USER_BADGES - Badge Notifications
-- ============================================================================
-- Cria notificação quando usuário conquista novo badge
CREATE TRIGGER badge_notify_only_trigger 
    AFTER INSERT ON public.user_badges 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_badge_notification_only();

-- ============================================================================
-- USER_STREAKS - Streak Notifications
-- ============================================================================
-- Cria notificação quando usuário atinge milestone de streak
CREATE TRIGGER streak_notify_only_trigger 
    AFTER UPDATE ON public.user_streaks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_streak_notification_only();

-- ============================================================================
-- NOTAS SOBRE TRIGGERS DE NOTIFICAÇÃO
-- ============================================================================
-- 
-- Funções Utilizadas:
-- - handle_holofote_notification(): Notificações de menções em holofotes
-- - handle_comment_notification_correto(): Notificações de comentários
-- - handle_comment_notification_only(): Notificações simplificadas de comentários
-- - handle_reaction_simple(): Notificações de reações
-- - handle_feedback_notification_correto(): Notificações de feedbacks
-- - handle_follow_notification_correto(): Notificações de follows
-- - handle_badge_notification_only(): Notificações de badges conquistados
-- - handle_streak_notification_only(): Notificações de streaks
-- 
-- Todas as funções: SECURITY INVOKER
-- 
-- Sistema de Notificações:
-- 1. Ação do usuário dispara trigger
-- 2. Trigger identifica usuários a serem notificados
-- 3. Notificação é criada na tabela notifications
-- 4. Sistema de agrupamento evita spam
-- 5. Prioridades são definidas por tipo de notificação
-- 
-- Tipos de Notificação:
-- - holofote: Quando usuário é mencionado em post
-- - comment: Quando post recebe comentário
-- - reaction: Quando post recebe reação
-- - feedback: Quando post recebe feedback
-- - follow: Quando usuário é seguido
-- - badge: Quando usuário conquista badge
-- - streak: Quando usuário atinge milestone de streak
-- 
-- Sistema Anti-Spam:
-- - Agrupamento por group_key
-- - Contadores de group_count
-- - Dados agregados em group_data (JSONB)
-- - Prioridades para ordenação
-- 
-- ============================================================================

