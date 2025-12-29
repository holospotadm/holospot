-- ============================================================================
-- FUNÇÃO: get_badge_bonus_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_badge_bonus_points(p_rarity text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_rarity
        WHEN 'common' THEN RETURN 5;
        WHEN 'rare' THEN RETURN 10;
        WHEN 'epic' THEN RETURN 15;
        WHEN 'legendary' THEN RETURN 20;
        ELSE RETURN 0;
    END CASE;
END;
$function$

