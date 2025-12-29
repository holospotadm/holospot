-- ============================================================================
-- TRIGGERS DA TABELA: user_points
-- ============================================================================

-- Trigger: auto_badge_check_bonus_user_points
CREATE TRIGGER auto_badge_check_bonus_user_points AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger: level_up_notification_trigger
CREATE TRIGGER level_up_notification_trigger AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_level_up_notification();

-- Trigger: update_user_points_updated_at
CREATE TRIGGER update_user_points_updated_at BEFORE UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_updated_at_column();

