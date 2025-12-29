-- ============================================================================
-- POLICIES (RLS) DA TABELA: points_history
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.points_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY Sistema pode inserir histórico de pontos ON public.points_history AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = user_id));

CREATE POLICY Users can delete points_history related to their posts ON public.points_history AS PERMISSIVE FOR DELETE USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM posts
  WHERE ((posts.id = points_history.post_id) AND (posts.user_id = auth.uid()))))));

CREATE POLICY Users can delete their own points_history ON public.points_history AS PERMISSIVE FOR DELETE USING ((auth.uid() = user_id));

CREATE POLICY Usuários podem ver seu próprio histórico ON public.points_history AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

CREATE POLICY points_history_insert_policy ON public.points_history AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY points_history_select_policy ON public.points_history AS PERMISSIVE FOR SELECT USING (true);

