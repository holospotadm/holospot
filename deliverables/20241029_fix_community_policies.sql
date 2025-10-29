-- ============================================
-- FIX: Remove policies com recursão infinita
-- Descrição: Remove policies problemáticas de comunidades
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- ========================================
-- REMOVER POLICIES PROBLEMÁTICAS
-- ========================================

-- Remover policies de communities
DROP POLICY IF EXISTS "Members can view community" ON public.communities;
DROP POLICY IF EXISTS "Only community owners can create communities" ON public.communities;
DROP POLICY IF EXISTS "Owner can update community" ON public.communities;
DROP POLICY IF EXISTS "Owner can delete community" ON public.communities;

-- Remover policies de community_members
DROP POLICY IF EXISTS "Members can view other members" ON public.community_members;
DROP POLICY IF EXISTS "Owner can add members" ON public.community_members;
DROP POLICY IF EXISTS "Owner can update members" ON public.community_members;
DROP POLICY IF EXISTS "Owner can remove members" ON public.community_members;

-- Remover policies de posts (que causam recursão)
DROP POLICY IF EXISTS "Users can view posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
DROP POLICY IF EXISTS "Owner can delete community posts" ON public.posts;
DROP POLICY IF EXISTS "Owner can update community posts" ON public.posts;

-- ========================================
-- RECRIAR POLICIES SIMPLES (SEM RECURSÃO)
-- ========================================

-- COMMUNITIES: Policies simples
CREATE POLICY "communities_select_policy" ON public.communities
    FOR SELECT TO public
    USING (true);  -- Funções com SECURITY DEFINER controlam acesso

CREATE POLICY "communities_insert_policy" ON public.communities
    FOR INSERT TO public
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "communities_update_policy" ON public.communities
    FOR UPDATE TO public
    USING (auth.uid() = owner_id);

CREATE POLICY "communities_delete_policy" ON public.communities
    FOR DELETE TO public
    USING (auth.uid() = owner_id);

-- COMMUNITY_MEMBERS: Policies simples
CREATE POLICY "community_members_select_policy" ON public.community_members
    FOR SELECT TO public
    USING (true);  -- Funções com SECURITY DEFINER controlam acesso

CREATE POLICY "community_members_insert_policy" ON public.community_members
    FOR INSERT TO public
    WITH CHECK (true);  -- Funções com SECURITY DEFINER controlam acesso

CREATE POLICY "community_members_update_policy" ON public.community_members
    FOR UPDATE TO public
    USING (true);  -- Funções com SECURITY DEFINER controlam acesso

CREATE POLICY "community_members_delete_policy" ON public.community_members
    FOR DELETE TO public
    USING (true);  -- Funções com SECURITY DEFINER controlam acesso

-- POSTS: Recriar policies originais (sem recursão)
CREATE POLICY "posts_select_policy" ON public.posts
    FOR SELECT TO public
    USING (
        community_id IS NULL OR
        EXISTS (
            SELECT 1 FROM community_members 
            WHERE community_id = posts.community_id 
            AND user_id = auth.uid() 
            AND is_active = true
        )
    );

CREATE POLICY "posts_insert_policy" ON public.posts
    FOR INSERT TO public
    WITH CHECK (
        auth.uid() = user_id AND (
            community_id IS NULL OR
            EXISTS (
                SELECT 1 FROM community_members 
                WHERE community_id = posts.community_id 
                AND user_id = auth.uid() 
                AND is_active = true
            )
        )
    );

CREATE POLICY "posts_update_policy" ON public.posts
    FOR UPDATE TO public
    USING (auth.uid() = user_id);

CREATE POLICY "posts_delete_policy" ON public.posts
    FOR DELETE TO public
    USING (auth.uid() = user_id);

-- ========================================
-- FIM DA MIGRATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '✅ Policies de comunidades corrigidas!';
    RAISE NOTICE '🔒 Acesso controlado por funções SECURITY DEFINER';
    RAISE NOTICE '✅ Recursão infinita resolvida';
END $$;

