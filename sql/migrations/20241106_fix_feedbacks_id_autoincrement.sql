-- ============================================================================
-- FIX: Adicionar auto-incremento ao campo id da tabela feedbacks
-- ============================================================================
-- Data: 2025-11-06
-- Problema: Campo id é BIGINT PRIMARY KEY mas sem auto-incremento
-- Erro: "invalid input syntax for type integer: '(0,0,)'"
-- Solução: Criar sequence e configurar como GENERATED ALWAYS AS IDENTITY
-- ============================================================================

-- Criar sequence para feedbacks
CREATE SEQUENCE IF NOT EXISTS public.feedbacks_id_seq;

-- Alterar coluna id para usar a sequence
ALTER TABLE public.feedbacks 
ALTER COLUMN id SET DEFAULT nextval('public.feedbacks_id_seq');

-- Configurar sequence para começar do próximo valor disponível
SELECT setval('public.feedbacks_id_seq', COALESCE((SELECT MAX(id) FROM public.feedbacks), 0) + 1, false);

-- Garantir que a sequence pertence à tabela
ALTER SEQUENCE public.feedbacks_id_seq OWNED BY public.feedbacks.id;

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Para verificar se funcionou:
-- SELECT column_name, column_default, is_nullable, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'feedbacks' AND column_name = 'id';
-- ============================================================================
