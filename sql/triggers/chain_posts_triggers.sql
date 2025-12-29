-- ============================================================================
-- TRIGGERS DA TABELA: chain_posts
-- ============================================================================

-- Trigger: trigger_check_chain_participation_badges
CREATE TRIGGER trigger_check_chain_participation_badges AFTER INSERT ON public.chain_posts FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION check_chain_participation_badges();

