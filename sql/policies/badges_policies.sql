-- ============================================================================
-- POLICIES (RLS) DA TABELA: badges
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY Badges são públicos ON public.badges AS PERMISSIVE FOR SELECT USING (true);

