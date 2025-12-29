-- ============================================================================
-- TRIGGERS DA TABELA: chains
-- ============================================================================

-- Trigger: trigger_check_chain_creation_badges
CREATE TRIGGER trigger_check_chain_creation_badges AFTER INSERT ON public.chains FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION check_chain_creation_badges();

