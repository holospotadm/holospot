-- ============================================================================
-- Create: Função read-only para obter streak sem atualizar
-- ============================================================================
-- Data: 2025-11-12
-- Problema: update_user_streak_with_data() incrementa streak ao carregar perfil
-- Causa: Função é chamada no carregamento da página, não apenas em atividades
-- Solução: Criar get_user_streak() que apenas LÊ sem atualizar
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_user_streak(UUID);

CREATE OR REPLACE FUNCTION public.get_user_streak(p_user_id UUID)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    next_milestone INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    -- Apenas ler dados de user_streaks, SEM atualizar
    RETURN QUERY
    SELECT 
        user_streaks.current_streak,
        user_streaks.longest_streak,
        user_streaks.last_activity_date,
        user_streaks.next_milestone
    FROM user_streaks
    WHERE user_streaks.user_id = p_user_id;
    
    -- Se não existe registro, retornar valores zerados
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 0, NULL::DATE, 7;
    END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_user_streak(UUID) TO authenticated;

-- ============================================================================
-- COMO USAR
-- ============================================================================
-- NO CARREGAMENTO DA PÁGINA (apenas ler):
--   SELECT * FROM get_user_streak('user-id');
--
-- APÓS ATIVIDADE (atualizar e retornar):
--   SELECT * FROM update_user_streak_with_data('user-id');
-- ============================================================================
