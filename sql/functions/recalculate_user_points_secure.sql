-- ============================================================================
-- FUNÇÃO: recalculate_user_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_points_secure(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    new_total INTEGER;
BEGIN
    -- Calcular total de pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO new_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Atualizar user_points
    INSERT INTO public.user_points (user_id, total_points, updated_at)
    VALUES (p_user_id, new_total, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = new_total,
        updated_at = NOW();
    
    RETURN new_total;
END;
$function$

