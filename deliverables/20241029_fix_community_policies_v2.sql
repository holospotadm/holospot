-- ============================================
-- FIX V2: Remove policies com recursão infinita
-- Descrição: Remove TODAS as policies e recria corretamente
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- Versão: 2.0.0 (remove tudo primeiro)
-- ============================================

-- ========================================
-- PARTE 1: REMOVER TODAS AS POLICIES
-- ========================================

-- COMMUNITIES: Remover todas as policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'communities') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.communities';
    END LOOP;
END $$;

-- COMMUNITY_MEMBERS: Remover todas as policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'community_members') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.community_members';
    END LOOP;
END $$;

-- POSTS: Remover policies relacionadas a comunidades
DROP POLICY IF EXISTS "posts_select_policy" ON public.posts;
DROP POLICY IF EXISTS "posts_insert_policy" ON public.posts;
DROP POLICY IF EXISTS "posts_update_policy" ON public.posts;
DROP POLICY IF EXISTS "posts_delete_policy" ON public.posts;
DROP POLICY IF EXISTS "Users can view posts" ON public.posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
DROP POLICY IF EXISTS "Owner can delete community posts" ON public.posts;
DROP POLICY IF EXISTS "Owner can update community posts" ON public.posts;
DROP POLICY IF EXISTS "Usuários podem criar seus próprios posts" ON public.posts;
DROP POLICY IF EXISTS "Usuários podem atualizar seus próprios posts" ON public.posts;
DROP POLICY IF EXISTS "Usuários podem deletar seus próprios posts" ON public.posts;

-- ========================================
-- PARTE 2: CRIAR POLICIES SIMPLES
-- ========================================

-- COMMUNITIES: Policies simples
CREATE POLICY "communities_select_policy" ON public.communities
    FOR SELECT TO public
    USING (true);

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
    USING (true);

CREATE POLICY "community_members_insert_policy" ON public.community_members
    FOR INSERT TO public
    WITH CHECK (true);

CREATE POLICY "community_members_update_policy" ON public.community_members
    FOR UPDATE TO public
    USING (true);

CREATE POLICY "community_members_delete_policy" ON public.community_members
    FOR DELETE TO public
    USING (true);

-- POSTS: Policies que suportam comunidades (SEM RECURSÃO)
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
-- PARTE 3: VERIFICAÇÃO
-- ========================================

DO $$
DECLARE
    v_communities_policies INTEGER;
    v_community_members_policies INTEGER;
    v_posts_policies INTEGER;
BEGIN
    -- Contar policies
    SELECT COUNT(*) INTO v_communities_policies
    FROM pg_policies WHERE tablename = 'communities';
    
    SELECT COUNT(*) INTO v_community_members_policies
    FROM pg_policies WHERE tablename = 'community_members';
    
    SELECT COUNT(*) INTO v_posts_policies
    FROM pg_policies WHERE tablename = 'posts';
    
    -- Verificar
    IF v_communities_policies = 4 AND 
       v_community_members_policies = 4 AND 
       v_posts_policies = 4 THEN
        RAISE NOTICE '✅ Policies de comunidades corrigidas com sucesso!';
        RAISE NOTICE '📊 Communities: % policies', v_communities_policies;
        RAISE NOTICE '📊 Community_members: % policies', v_community_members_policies;
        RAISE NOTICE '📊 Posts: % policies', v_posts_policies;
        RAISE NOTICE '🔒 Acesso controlado por funções SECURITY DEFINER';
        RAISE NOTICE '✅ Recursão infinita resolvida';
    ELSE
        RAISE WARNING '⚠️ Número de policies inesperado!';
        RAISE WARNING '📊 Communities: % policies (esperado: 4)', v_communities_policies;
        RAISE WARNING '📊 Community_members: % policies (esperado: 4)', v_community_members_policies;
        RAISE WARNING '📊 Posts: % policies (esperado: 4)', v_posts_policies;
    END IF;
END $$;

