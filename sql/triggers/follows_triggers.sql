-- ============================================================================
-- TRIGGERS DA TABELA: follows
-- ============================================================================

-- Trigger: follow_notification_correto_trigger
CREATE TRIGGER follow_notification_correto_trigger AFTER INSERT ON public.follows FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION handle_follow_notification_correto();

