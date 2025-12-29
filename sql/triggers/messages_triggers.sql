-- ============================================================================
-- TRIGGERS DA TABELA: messages
-- ============================================================================

-- Trigger: trigger_update_conversation_timestamp
CREATE TRIGGER trigger_update_conversation_timestamp AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_conversation_timestamp();

