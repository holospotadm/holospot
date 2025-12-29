-- ============================================================================
-- POLICIES (RLS) DA TABELA: communities
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY communities_delete_policy ON public.communities AS PERMISSIVE FOR DELETE USING ((auth.uid() = owner_id));

CREATE POLICY communities_insert_policy ON public.communities AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = owner_id));

CREATE POLICY communities_select_policy ON public.communities AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY communities_update_policy ON public.communities AS PERMISSIVE FOR UPDATE USING ((auth.uid() = owner_id));

