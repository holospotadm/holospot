-- ============================================================================
-- Adicionar coluna longest_streak na tabela user_streaks
-- ============================================================================
-- Data: 2025-11-12
-- Objetivo: Armazenar o maior streak já alcançado pelo usuário
-- ============================================================================

-- Adicionar coluna longest_streak
ALTER TABLE public.user_streaks 
ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;

-- Atualizar valores existentes (longest_streak = current_streak para usuários existentes)
UPDATE public.user_streaks 
SET longest_streak = current_streak 
WHERE longest_streak IS NULL OR longest_streak = 0;

-- Adicionar comentário
COMMENT ON COLUMN public.user_streaks.longest_streak IS 
'Maior sequência de dias consecutivos já alcançada pelo usuário (recorde pessoal)';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'user_streaks'
-- ORDER BY ordinal_position;
-- ============================================================================
