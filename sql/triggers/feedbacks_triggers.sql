-- ============================================================================
-- TRIGGERS DA TABELA FEEDBACKS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 4
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: auto_badge_check_bonus_feedbacks
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_feedbacks AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER: feedback_insert_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER feedback_insert_secure_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION handle_feedback_insert_secure();

-- TRIGGER: feedback_notification_correto_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER feedback_notification_correto_trigger AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION handle_feedback_notification_correto();

-- TRIGGER: update_streak_after_feedback
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_streak_after_feedback AFTER INSERT ON public.feedbacks FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

