-- ============================================================================
-- TRIGGERS DA TABELA: comments
-- ============================================================================

-- Trigger: auto_badge_check_bonus_comments
CREATE TRIGGER auto_badge_check_bonus_comments AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger: comment_delete_secure_trigger
CREATE TRIGGER comment_delete_secure_trigger AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_comment_delete_secure();

-- Trigger: comment_insert_secure_trigger
CREATE TRIGGER comment_insert_secure_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_comment_insert_secure();

-- Trigger: comment_notification_correto_trigger
CREATE TRIGGER comment_notification_correto_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_comment_notification_correto();

-- Trigger: update_streak_after_comment
CREATE TRIGGER update_streak_after_comment AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_user_streak_trigger();

