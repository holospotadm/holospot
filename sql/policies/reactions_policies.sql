-- ============================================================================
-- POLICIES (RLS) DA TABELA: reactions
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY Reações são visíveis para todos ON public.reactions AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY Users can create reactions ON public.reactions AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = user_id));

CREATE POLICY Usuários podem criar suas próprias reações ON public.reactions AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = user_id));

CREATE POLICY Usuários podem deletar suas próprias reações ON public.reactions AS PERMISSIVE FOR DELETE USING ((auth.uid() = user_id));

CREATE POLICY reactions_delete_policy ON public.reactions AS PERMISSIVE FOR DELETE USING (true);

CREATE POLICY reactions_insert_policy ON public.reactions AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY reactions_select_policy ON public.reactions AS PERMISSIVE FOR SELECT USING (true);

