-- ============================================================================
-- POLICIES (RLS) DA TABELA: feedbacks
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;

CREATE POLICY Enable insert for authenticated users only ON public.feedbacks AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY Enable read access for all users ON public.feedbacks AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY feedbacks_delete_policy ON public.feedbacks AS PERMISSIVE FOR DELETE USING (true);

CREATE POLICY feedbacks_insert_policy ON public.feedbacks AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY feedbacks_select_policy ON public.feedbacks AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY feedbacks_update_policy ON public.feedbacks AS PERMISSIVE FOR UPDATE USING (true);

