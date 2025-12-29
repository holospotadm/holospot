-- ============================================================================
-- POLICIES (RLS) DA TABELA: community_members
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY community_members_delete_policy ON public.community_members AS PERMISSIVE FOR DELETE USING (true);

CREATE POLICY community_members_insert_policy ON public.community_members AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY community_members_select_policy ON public.community_members AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY community_members_update_policy ON public.community_members AS PERMISSIVE FOR UPDATE USING (true);

