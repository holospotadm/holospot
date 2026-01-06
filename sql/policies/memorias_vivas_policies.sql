-- ============================================================================
-- POLICIES RLS: Memórias Vivas
-- Descrição: Políticas de segurança para o feed Memórias Vivas
-- ============================================================================

-- ============================================================================
-- POLICY PARA POSTS
-- ============================================================================

-- Remover policy antiga se existir
DROP POLICY IF EXISTS "Allow 60+ to post in Memórias Vivas" ON public.posts;
DROP POLICY IF EXISTS "posts_memorias_vivas_insert" ON public.posts;

-- Criar policy para INSERT em posts do Memórias Vivas
-- Esta policy permite:
-- 1. Posts em qualquer comunidade que NÃO seja Memórias Vivas
-- 2. Posts no Memórias Vivas APENAS se o usuário tiver 60+
CREATE POLICY "posts_memorias_vivas_insert" ON public.posts
FOR INSERT
WITH CHECK (
    community_id IS NULL 
    OR community_id != get_memorias_vivas_community_id()
    OR can_post_in_memorias_vivas(auth.uid())
);

-- ============================================================================
-- POLICY PARA FEEDBACKS
-- ============================================================================

-- Remover policy antiga se existir
DROP POLICY IF EXISTS "Allow 60+ to give feedback in Memórias Vivas" ON public.feedbacks;
DROP POLICY IF EXISTS "feedbacks_memorias_vivas_insert" ON public.feedbacks;

-- Criar policy para INSERT em feedbacks do Memórias Vivas
-- Esta policy permite:
-- 1. Feedbacks em posts que NÃO são do Memórias Vivas (regra normal: apenas mentioned_user)
-- 2. Feedbacks em posts do Memórias Vivas se o usuário tiver 60+
CREATE POLICY "feedbacks_memorias_vivas_insert" ON public.feedbacks
FOR INSERT
WITH CHECK (
    -- Se o post NÃO é do Memórias Vivas, usar regra normal
    (SELECT community_id FROM public.posts WHERE id = post_id) != get_memorias_vivas_community_id()
    OR
    -- Se o post É do Memórias Vivas, verificar se usuário tem 60+
    can_give_feedback_in_memorias_vivas(auth.uid(), post_id)
);
