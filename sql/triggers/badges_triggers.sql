-- ============================================================================
-- TRIGGERS DA TABELA BADGES - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de triggers: 1
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- TRIGGER: update_badges_updated_at
-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE TRIGGER update_badges_updated_at BEFORE UPDATE ON public.badges FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

