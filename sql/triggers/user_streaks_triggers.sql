-- ============================================================================
-- TRIGGERS DA TABELA: user_streaks
-- ============================================================================

-- Trigger: streak_notify_only_trigger
CREATE TRIGGER streak_notify_only_trigger AFTER UPDATE ON public.user_streaks FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_streak_notification_only();

