-- ============================================================================
-- TRIGGERS DA TABELA USER_STREAKS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 1
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: streak_notify_only_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER streak_notify_only_trigger AFTER UPDATE ON public.user_streaks FOR EACH ROW EXECUTE FUNCTION handle_streak_notification_only();

