-- ============================================================================
-- FUNÇÃO: calculate_streak_bonus_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_streak_bonus(p_points integer, p_milestone integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_multiplier DECIMAL(3,2);
BEGIN
    CASE p_milestone
        WHEN 7 THEN v_multiplier := 1.2;   -- +20%
        WHEN 30 THEN v_multiplier := 1.5;  -- +50%
        WHEN 180 THEN v_multiplier := 1.8; -- +80%
        WHEN 365 THEN v_multiplier := 2.0; -- +100%
        ELSE v_multiplier := 1.0;
    END CASE;
    
    -- Bonus = Pontos × (Multiplicador - 1)
    RETURN ROUND(p_points * (v_multiplier - 1));
END;
$function$

