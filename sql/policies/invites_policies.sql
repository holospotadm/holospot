-- ============================================================================
-- POLICIES (RLS) DA TABELA: invites
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY Anyone can read invites ON public.invites AS PERMISSIVE FOR SELECT TO authenticated USING (true);

CREATE POLICY Authenticated users can insert invites ON public.invites AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY Authenticated users can update invites ON public.invites AS PERMISSIVE FOR UPDATE TO authenticated USING (true);

