-- ============================================================================
-- FUNÇÃO: calculate_age
-- Descrição: Calcula a idade em anos a partir da data de nascimento
-- ============================================================================

CREATE OR REPLACE FUNCTION public.calculate_age(birth_date DATE)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $function$
BEGIN
    IF birth_date IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INTEGER;
END;
$function$;

COMMENT ON FUNCTION public.calculate_age(DATE) IS 'Calcula a idade em anos a partir da data de nascimento';
