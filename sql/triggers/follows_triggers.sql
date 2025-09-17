-- ============================================================================
-- TRIGGERS DA TABELA FOLLOWS - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 1
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: follow_notification_correto_trigger
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER follow_notification_correto_trigger AFTER INSERT ON public.follows FOR EACH ROW EXECUTE FUNCTION handle_follow_notification_correto();

