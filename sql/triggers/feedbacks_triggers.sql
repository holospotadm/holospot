-- ============================================================================
-- TRIGGERS DA TABELA: feedbacks
-- ============================================================================

-- Trigger: auto_badge_check_bonus_feedbacks
CREATE TRIGGER auto_badge_check_bonus_feedbacks AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger: feedback_insert_secure_trigger
CREATE TRIGGER feedback_insert_secure_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_feedback_insert_secure();

-- Trigger: feedback_notification_correto_trigger
CREATE TRIGGER feedback_notification_correto_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_feedback_notification_correto();

-- Trigger: update_streak_after_feedback
CREATE TRIGGER update_streak_after_feedback AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_user_streak_trigger();

