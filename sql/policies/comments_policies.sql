-- ============================================================================
-- POLICIES (RLS) DA TABELA: comments
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY Enable insert for authenticated users only ON public.comments AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY Enable read access for all users ON public.comments AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY comments_delete_policy ON public.comments AS PERMISSIVE FOR DELETE USING (true);

CREATE POLICY comments_insert_policy ON public.comments AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY comments_select_policy ON public.comments AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY comments_update_policy ON public.comments AS PERMISSIVE FOR UPDATE USING (true);

