-- ============================================================================
-- POLICIES (RLS) DA TABELA: posts
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Policy: Todos podem ver posts públicos
CREATE POLICY "Posts são visíveis para todos" ON public.posts 
AS PERMISSIVE FOR SELECT 
USING (true);

-- Policy: Usuários podem deletar seus próprios posts
CREATE POLICY posts_delete_policy ON public.posts 
AS PERMISSIVE FOR DELETE 
USING ((auth.uid() = user_id));

-- Policy: Usuários podem inserir posts:
-- 1. No feed geral (sem comunidade)
-- 2. Em comunidades onde são membros
-- 3. No Memórias Vivas se tiverem 60+ anos (sem exigir membership)
CREATE POLICY posts_insert_policy ON public.posts 
AS PERMISSIVE FOR INSERT 
WITH CHECK (
    (auth.uid() = user_id) 
    AND 
    (
        -- Feed geral (sem comunidade)
        (community_id IS NULL) 
        OR 
        -- Comunidades normais (exige membership)
        (
            community_id != get_memorias_vivas_community_id()
            AND
            EXISTS (
                SELECT 1
                FROM community_members
                WHERE community_members.community_id = posts.community_id 
                AND community_members.user_id = auth.uid() 
                AND community_members.is_active = true
            )
        )
        OR
        -- Memórias Vivas (exige idade >= 60, não exige membership)
        (
            community_id = get_memorias_vivas_community_id()
            AND
            can_post_in_memorias_vivas(auth.uid())
        )
    )
);

-- Policy: Usuários podem ver posts:
-- 1. Do feed geral
-- 2. De comunidades onde são membros
-- 3. Do Memórias Vivas (acesso universal)
CREATE POLICY posts_select_policy ON public.posts 
AS PERMISSIVE FOR SELECT 
USING (
    (community_id IS NULL) 
    OR 
    (
        community_id != get_memorias_vivas_community_id()
        AND
        EXISTS (
            SELECT 1
            FROM community_members
            WHERE community_members.community_id = posts.community_id 
            AND community_members.user_id = auth.uid() 
            AND community_members.is_active = true
        )
    )
    OR
    (community_id = get_memorias_vivas_community_id())
);

-- Policy: Usuários podem atualizar seus próprios posts
CREATE POLICY posts_update_policy ON public.posts 
AS PERMISSIVE FOR UPDATE 
USING ((auth.uid() = user_id));
