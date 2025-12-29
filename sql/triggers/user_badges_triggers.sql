-- ============================================================================
-- TRIGGERS DA TABELA: user_badges
-- ============================================================================

-- Trigger: badge_notify_only_trigger
CREATE TRIGGER badge_notify_only_trigger AFTER INSERT ON public.user_badges FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_badge_notification_only();

