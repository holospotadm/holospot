-- ============================================================================
-- POLICIES (RLS) DA TABELA: levels
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY Níveis são públicos ON public.levels AS PERMISSIVE FOR SELECT USING (true);

