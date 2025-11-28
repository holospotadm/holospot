-- ============================================================================
-- Fix: Corrigir retorno de update_user_streak_with_data
-- ============================================================================
-- Data: 2025-11-12
-- Problema: Função retorna NULL em todos os campos
-- Causa: update_user_streak_incremental retorna 6 campos mas wrapper retorna 5
-- Solução: Adicionar milestone_value ao RETURNS TABLE
-- ============================================================================

DROP FUNCTION IF EXISTS public.update_user_streak_with_data(UUID);

CREATE OR REPLACE FUNCTION public.update_user_streak_with_data(p_user_id UUID)
RETURNS TABLE (
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    milestone_reached BOOLEAN,
    milestone_value INTEGER,  -- ← ADICIONADO
    bonus_points INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_result RECORD;
BEGIN
    -- Chamar função incremental e pegar resultado
    SELECT * INTO v_result FROM update_user_streak_incremental(p_user_id);
    
    -- Retornar TODOS os 6 campos
    RETURN QUERY SELECT 
        v_result.current_streak,
        v_result.longest_streak,
        v_result.last_activity_date,
        v_result.milestone_reached,
        v_result.milestone_value,  -- ← ADICIONADO
        v_result.bonus_points;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.update_user_streak_with_data(UUID) TO authenticated;

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- SELECT * FROM update_user_streak_with_data('SEU-USER-ID');
-- Deve retornar valores corretos, não NULL
-- ============================================================================
