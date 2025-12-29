-- ============================================================================
-- FUNÇÃO: check_username_availability
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_username_availability(p_username text, p_current_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Verificar se username já existe (ignorando o próprio usuário)
    -- Case-insensitive: João = joão = JOÃO
    SELECT EXISTS(
        SELECT 1 
        FROM profiles 
        WHERE LOWER(username) = LOWER(p_username) 
        AND id != p_current_user_id
    ) INTO v_exists;
    
    -- Retornar TRUE se disponível (não existe)
    RETURN NOT v_exists;
END;
$function$

