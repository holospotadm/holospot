-- ============================================================================
-- FUNÇÃO: can_post_in_memorias_vivas
-- Descrição: Verifica se o usuário tem 60+ anos e pode postar no Memórias Vivas
-- ============================================================================

CREATE OR REPLACE FUNCTION public.can_post_in_memorias_vivas(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    user_age INTEGER;
BEGIN
    SELECT calculate_age(birth_date) INTO user_age
    FROM public.profiles
    WHERE id = user_id;
    
    RETURN COALESCE(user_age, 0) >= 60;
END;
$$;

COMMENT ON FUNCTION public.can_post_in_memorias_vivas(UUID) IS 'Verifica se o usuário tem 60+ anos e pode postar no Memórias Vivas';
