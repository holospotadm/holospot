-- ============================================================================
-- FUNÇÃO: get_previous_milestone
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_previous_milestone(p_next integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_next
        WHEN 30 THEN RETURN 7;   -- Se próximo é 30, anterior era 7
        WHEN 180 THEN RETURN 30; -- Se próximo é 180, anterior era 30
        WHEN 365 THEN RETURN 180; -- Se próximo é 365, anterior era 180
        WHEN 7 THEN RETURN 365;   -- Se próximo é 7 (reset), anterior era 365
        ELSE RETURN 7;
    END CASE;
END;
$function$

