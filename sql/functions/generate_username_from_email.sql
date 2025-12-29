-- ============================================================================
-- FUNÇÃO: generate_username_from_email
-- ============================================================================

CREATE OR REPLACE FUNCTION public.generate_username_from_email()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Se username não foi fornecido e email existe, gerar automaticamente
    IF NEW.username IS NULL AND NEW.email IS NOT NULL THEN
        NEW.username = SPLIT_PART(NEW.email, '@', 1);
    END IF;
    
    RETURN NEW;
END;
$function$

