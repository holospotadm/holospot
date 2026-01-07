-- ============================================================================
-- CORREÇÃO: Permitir INSERT de posts no Memórias Vivas para usuários 60+
-- Data: 2025-01-06
-- Descrição: Atualiza a policy de INSERT para permitir posts no Memórias Vivas
--            sem exigir membership, apenas verificando idade >= 60
-- ============================================================================

-- Remover a policy antiga
DROP POLICY IF EXISTS posts_insert_policy ON public.posts;

-- Criar nova policy que permite:
-- 1. Posts no feed geral (community_id IS NULL)
-- 2. Posts em comunidades onde o usuário é membro
-- 3. Posts no Memórias Vivas para usuários 60+ (sem exigir membership)
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

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Após executar, verifique com:
-- SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'posts' AND policyname = 'posts_insert_policy';
