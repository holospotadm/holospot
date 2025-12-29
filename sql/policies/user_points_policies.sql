-- ============================================================================
-- POLICIES (RLS) DA TABELA: user_points
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY Pontos são públicos para ranking ON public.user_points AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY Sistema pode inserir/atualizar pontos ON public.user_points AS PERMISSIVE FOR ALL USING ((auth.uid() = user_id));

CREATE POLICY Usuários podem ver seus próprios pontos ON public.user_points AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

CREATE POLICY user_points_insert_policy ON public.user_points AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY user_points_select_policy ON public.user_points AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY user_points_update_policy ON public.user_points AS PERMISSIVE FOR UPDATE USING (true) WITH CHECK (true);

