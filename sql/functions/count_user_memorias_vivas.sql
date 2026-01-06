-- ============================================================================
-- FUNÇÕES DE CONTAGEM: Memórias Vivas
-- Descrição: Funções para contar atividades dos usuários no Memórias Vivas
-- ============================================================================

-- Contar posts do usuário no Memórias Vivas
CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_posts(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.posts
    WHERE user_id = $1
    AND community_id = get_memorias_vivas_community_id();
$$;

-- Contar reações recebidas no Memórias Vivas
CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_reactions_received(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.reactions r
    JOIN public.posts p ON r.post_id = p.id
    WHERE p.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;

-- Contar reações dadas no Memórias Vivas
CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_reactions_given(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.reactions r
    JOIN public.posts p ON r.post_id = p.id
    WHERE r.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;

-- Contar comentários no Memórias Vivas
CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_comments(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.comments c
    JOIN public.posts p ON c.post_id = p.id
    WHERE c.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;
