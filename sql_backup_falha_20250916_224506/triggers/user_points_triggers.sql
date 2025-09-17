-- ============================================================================
-- TRIGGERS DA TABELA USER_POINTS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 3
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: auto_badge_check_bonus_user_points
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_user_points AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER: level_up_notification_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER level_up_notification_trigger AFTER UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION handle_level_up_notification();

-- TRIGGER: update_user_points_updated_at
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_user_points_updated_at BEFORE UPDATE ON public.user_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

