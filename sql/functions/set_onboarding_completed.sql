-- ============================================================================
-- FUNÇÃO: set_onboarding_completed
-- Descrição: Marca o tour de onboarding como concluído para o usuário autenticado
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_onboarding_completed()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.profiles
  SET has_completed_onboarding = true
  WHERE id = auth.uid();
$$;

COMMENT ON FUNCTION public.set_onboarding_completed() IS
'Marca o tour de onboarding como concluído para o usuário autenticado.';

GRANT EXECUTE ON FUNCTION public.set_onboarding_completed() TO authenticated;
