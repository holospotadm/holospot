-- ============================================================================
-- FUNÇÃO: can_give_feedback_in_memorias_vivas
-- Descrição: Verifica se o usuário pode dar feedback em um post do Memórias Vivas (60+ apenas)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.can_give_feedback_in_memorias_vivas(user_id UUID, target_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    user_age INTEGER;
    post_community_id UUID;
    memorias_vivas_id UUID;
BEGIN
    -- Buscar idade do usuário
    SELECT calculate_age(birth_date) INTO user_age
    FROM public.profiles
    WHERE id = user_id;
    
    -- Buscar community_id do post
    SELECT community_id INTO post_community_id
    FROM public.posts
    WHERE id = target_post_id;
    
    -- Buscar ID do Memórias Vivas
    SELECT get_memorias_vivas_community_id() INTO memorias_vivas_id;
    
    -- Verificar se o post é do Memórias Vivas E se o usuário tem 60+
    RETURN post_community_id = memorias_vivas_id AND COALESCE(user_age, 0) >= 60;
END;
$$;

COMMENT ON FUNCTION public.can_give_feedback_in_memorias_vivas(UUID, UUID) IS 'Verifica se o usuário pode dar feedback em um post do Memórias Vivas (60+ apenas)';
