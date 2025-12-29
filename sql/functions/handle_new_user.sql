-- ============================================================================
-- FUNÇÃO: handle_new_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- NÃO criar perfil automaticamente
    -- O perfil será criado pelo sistema de convites após validação
    RETURN NEW;
END;
$function$

