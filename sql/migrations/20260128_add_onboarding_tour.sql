-- ============================================================================
-- MIGRAÇÃO: Tour de Onboarding para Novos Usuários
-- Data: 28 de janeiro de 2026
-- Descrição: Adiciona coluna para rastrear status do onboarding e função RPC
-- ============================================================================

-- 1. Adicionar coluna para rastrear o status do onboarding
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.has_completed_onboarding IS
'Indica se o usuário já completou (ou pulou) o tour de onboarding inicial.';

-- 2. Criar função RPC para marcar onboarding como concluído
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
