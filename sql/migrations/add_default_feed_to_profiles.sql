-- ============================================================================
-- MIGRATION: Add default_feed column to profiles table
-- ============================================================================
-- Adiciona coluna para armazenar preferência de feed padrão do usuário
-- ============================================================================

-- Adicionar coluna default_feed
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS default_feed TEXT DEFAULT 'recommended';

-- Adicionar constraint para valores válidos
ALTER TABLE public.profiles
ADD CONSTRAINT check_default_feed_values 
CHECK (default_feed IN ('recommended', 'following'));

-- Comentário
COMMENT ON COLUMN public.profiles.default_feed IS 
'Feed padrão que aparece ao abrir o app: recommended (todos) ou following (apenas quem segue)';

-- ============================================================================
-- NOTAS
-- ============================================================================
-- 
-- Valores possíveis:
-- - 'recommended': Mostra todos os posts (feed recomendado)
-- - 'following': Mostra apenas posts de quem o usuário segue
-- 
-- Default: 'recommended' (comportamento padrão do app)
-- 
-- ============================================================================

