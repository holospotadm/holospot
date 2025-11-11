-- ============================================================================
-- DEBUG: Desabilitar triggers de feedbacks temporariamente
-- ============================================================================
-- Data: 2025-11-06
-- Problema: Erro "(0,0,)" ao inserir feedback
-- Estratégia: Desabilitar triggers para identificar qual está causando o erro
-- ============================================================================

-- Desabilitar os 3 triggers de feedbacks
ALTER TABLE public.feedbacks DISABLE TRIGGER auto_badge_check_bonus_feedbacks;
ALTER TABLE public.feedbacks DISABLE TRIGGER feedback_insert_secure_trigger;
ALTER TABLE public.feedbacks DISABLE TRIGGER feedback_notification_correto_trigger;

-- ============================================================================
-- INSTRUÇÕES PARA TESTE:
-- ============================================================================
-- 1. Execute esta migration
-- 2. Tente dar feedback
-- 3. Se funcionar, o erro está em um dos triggers
-- 4. Execute a migration de reabilitação para testar um por um
-- ============================================================================

-- Para reabilitar depois (NÃO EXECUTE AGORA):
-- ALTER TABLE public.feedbacks ENABLE TRIGGER auto_badge_check_bonus_feedbacks;
-- ALTER TABLE public.feedbacks ENABLE TRIGGER feedback_insert_secure_trigger;
-- ALTER TABLE public.feedbacks ENABLE TRIGGER feedback_notification_correto_trigger;
-- ============================================================================
