-- ============================================================================
-- FUNÇÃO: get_next_milestone
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_next_milestone(p_current integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    CASE p_current
        WHEN 7 THEN RETURN 30;   -- 7 dias → próximo é 30 dias
        WHEN 30 THEN RETURN 180; -- 30 dias → próximo é 180 dias
        WHEN 180 THEN RETURN 365; -- 180 dias → próximo é 365 dias
        WHEN 365 THEN RETURN 7;   -- 365 dias → reset para 7 dias
        ELSE RETURN 7;            -- Default: começar com 7 dias
    END CASE;
END;
$function$

