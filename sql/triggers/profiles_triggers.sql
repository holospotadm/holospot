-- ============================================================================
-- TRIGGERS DA TABELA: profiles
-- ============================================================================

-- Trigger: trigger_generate_username
CREATE TRIGGER trigger_generate_username BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION generate_username_from_email();

-- Trigger: trigger_generate_username
CREATE TRIGGER trigger_generate_username BEFORE INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION EXECUTE FUNCTION generate_username_from_email();

