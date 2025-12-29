-- ============================================================================
-- POLICIES (RLS) DA TABELA: posts
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY Posts são visíveis para todos ON public.posts AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY posts_delete_policy ON public.posts AS PERMISSIVE FOR DELETE USING ((auth.uid() = user_id));

CREATE POLICY posts_insert_policy ON public.posts AS PERMISSIVE FOR INSERT WITH CHECK (((auth.uid() = user_id) AND ((community_id IS NULL) OR (EXISTS ( SELECT 1
   FROM community_members
  WHERE ((community_members.community_id = posts.community_id) AND (community_members.user_id = auth.uid()) AND (community_members.is_active = true)))))));

CREATE POLICY posts_select_policy ON public.posts AS PERMISSIVE FOR SELECT USING (((community_id IS NULL) OR (EXISTS ( SELECT 1
   FROM community_members
  WHERE ((community_members.community_id = posts.community_id) AND (community_members.user_id = auth.uid()) AND (community_members.is_active = true))))));

CREATE POLICY posts_update_policy ON public.posts AS PERMISSIVE FOR UPDATE USING ((auth.uid() = user_id));

