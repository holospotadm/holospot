-- ============================================================================
-- POLICIES (RLS) DA TABELA: user_badges
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY Badges de usuários são públicos para leitura ON public.user_badges AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY Sistema pode inserir badges de usuários ON public.user_badges AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = user_id));

CREATE POLICY Usuários podem ver seus próprios badges ON public.user_badges AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

