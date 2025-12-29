-- ============================================================================
-- FUNÇÃO: calculate_streak_bonus
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_user_id uuid, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
    v_days_back INTEGER;
    v_points_period INTEGER;
    v_bonus INTEGER;
BEGIN
    -- Determinar multiplicador e período baseado no milestone
    CASE p_milestone
        WHEN 7 THEN 
            v_multiplier := 1.2;   -- +20%
            v_days_back := 7;
        WHEN 30 THEN 
            v_multiplier := 1.5;   -- +50%
            v_days_back := 30;
        WHEN 182 THEN 
            v_multiplier := 1.8;   -- +80%
            v_days_back := 182;
        WHEN 365 THEN 
            v_multiplier := 2.0;   -- +100%
            v_days_back := 365;
        ELSE 
            v_multiplier := 1.0;
            v_days_back := 0;
    END CASE;
    
    -- Se não é um milestone válido, retornar 0
    IF v_days_back = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular pontos dos últimos X dias (EXCLUINDO todos os tipos de bônus)
    SELECT COALESCE(SUM(points_earned), 0) INTO v_points_period
    FROM public.points_history 
    WHERE user_id = p_user_id
    AND created_at >= (CURRENT_DATE - INTERVAL '1 day' * v_days_back)
    AND action_type NOT IN ('streak_bonus', 'streak_bonus_retroactive', 'streak_bonus_correction'); -- Excluir todos os bônus
    
    -- Calcular bônus: Pontos do período × (Multiplicador - 1)
    v_bonus := ROUND(v_points_period * (v_multiplier - 1));
    
    RAISE NOTICE 'Cálculo de bônus: User % - Milestone % dias - Pontos período: % - Bônus: %', 
        p_user_id, p_milestone, v_points_period, v_bonus;
    
    RETURN v_bonus;
END;
$function$

