-- ============================================================================
-- TRIGGERS DA TABELA PROFILES - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 1
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: trigger_generate_username
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER trigger_generate_username BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION generate_username_from_email();

