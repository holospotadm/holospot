-- ============================================================================
-- TRIGGERS DA TABELA USER_BADGES - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 1
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: badge_notify_only_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER badge_notify_only_trigger AFTER INSERT ON public.user_badges FOR EACH ROW EXECUTE FUNCTION handle_badge_notification_only();

