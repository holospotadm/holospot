-- ============================================================================
-- FUNÇÃO: sync_user_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sync_user_points(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    calculated_total INTEGER;
BEGIN
    -- Calcular total real dos pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO calculated_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Atualizar ou inserir na tabela user_points
    INSERT INTO public.user_points (user_id, total_points, updated_at)
    VALUES (p_user_id, calculated_total, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = calculated_total,
        updated_at = NOW();
    
    RETURN calculated_total;
END;
$function$

