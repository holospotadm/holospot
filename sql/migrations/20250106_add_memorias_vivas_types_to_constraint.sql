-- ============================================================================
-- CORREÇÃO: Adicionar tipos do Memórias Vivas na constraint posts_type_check
-- Data: 2025-01-06
-- Descrição: Atualiza a constraint para aceitar os novos tipos de post do
--            feed Memórias Vivas
-- ============================================================================

-- Remover a constraint antiga
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_type_check;

-- Criar nova constraint incluindo os tipos do Memórias Vivas
ALTER TABLE public.posts ADD CONSTRAINT posts_type_check CHECK (
    type = ANY (ARRAY[
        -- Tipos originais
        'gratitude'::text, 
        'achievement'::text, 
        'memory'::text, 
        'inspiration'::text, 
        'support'::text, 
        'admiration'::text,
        -- Tipos do Memórias Vivas
        'memoria_mv'::text,
        'conselho_mv'::text,
        'epoca_ouro_mv'::text,
        'historia_mv'::text,
        'licao_vida_mv'::text,
        'tradicao_mv'::text
    ])
);

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
-- Após executar, verifique com:
-- SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'posts_type_check';
