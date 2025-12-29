-- ============================================================================
-- POLICIES (RLS) DA TABELA: waitlist
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY Anyone can insert to waitlist ON public.waitlist AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY Anyone can read waitlist ON public.waitlist AS PERMISSIVE FOR SELECT TO authenticated USING (true);

CREATE POLICY Authenticated users can update waitlist ON public.waitlist AS PERMISSIVE FOR UPDATE TO authenticated USING (true);

