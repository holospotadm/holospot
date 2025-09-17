-- ============================================================================
-- TRIGGERS DA TABELA COMMENTS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 6
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: auto_badge_check_bonus_comments
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER auto_badge_check_bonus_comments AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- TRIGGER: comment_delete_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER comment_delete_secure_trigger AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_delete_secure();

-- TRIGGER: comment_insert_secure_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER comment_insert_secure_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_insert_secure();

-- TRIGGER: comment_notification_correto_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER comment_notification_correto_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_notification_correto();

-- TRIGGER: comment_notify_only_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER comment_notify_only_trigger AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION handle_comment_notification_only();

-- TRIGGER: update_streak_after_comment
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_streak_after_comment AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION update_user_streak_trigger();

