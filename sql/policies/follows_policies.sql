-- ============================================================================
-- POLICIES (RLS) DA TABELA: follows
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY Follows são visíveis para todos ON public.follows AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY Usuários podem criar seus próprios follows ON public.follows AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = follower_id));

CREATE POLICY Usuários podem deletar seus próprios follows ON public.follows AS PERMISSIVE FOR DELETE USING ((auth.uid() = follower_id));

