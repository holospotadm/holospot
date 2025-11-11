-- ============================================================================
-- FIX: Remover DEFAULT VALUES problemáticos da tabela feedbacks
-- ============================================================================
-- Data: 2025-11-06
-- Problema: Erro "(0,0,)" ao inserir feedback mesmo com triggers desabilitados
-- Hipótese: DEFAULT gen_random_uuid() pode estar causando conflito
-- Solução: Remover defaults de post_id e author_id (sempre enviados explicitamente)
-- ============================================================================

-- Remover DEFAULT de post_id
ALTER TABLE public.feedbacks 
ALTER COLUMN post_id DROP DEFAULT;

-- Remover DEFAULT de author_id
ALTER TABLE public.feedbacks 
ALTER COLUMN author_id DROP DEFAULT;

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Para verificar se funcionou:
-- SELECT column_name, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'feedbacks' AND column_name IN ('post_id', 'author_id');
-- 
-- Resultado esperado: column_default = NULL para ambos
-- ============================================================================

-- ============================================================================
-- NOTAS
-- ============================================================================
-- - post_id e author_id sempre são enviados explicitamente no INSERT
-- - Não há necessidade de DEFAULT para esses campos
-- - mentioned_user_id não tem DEFAULT e funciona corretamente
-- ============================================================================
