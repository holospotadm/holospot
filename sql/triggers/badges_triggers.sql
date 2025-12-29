-- ============================================================================
-- TRIGGERS DA TABELA: badges
-- ============================================================================

-- Trigger: update_badges_updated_at
CREATE TRIGGER update_badges_updated_at BEFORE UPDATE ON public.badges FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION update_updated_at_column();

