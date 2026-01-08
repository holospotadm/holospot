-- ============================================================================
-- MIGRAÇÃO: Adicionar suporte para Correntes do Memórias Vivas
-- Data: 2026-01-07
-- Descrição: Adiciona coluna is_memorias_vivas à tabela chains para identificar
--            correntes restritas a usuários 60+
-- ============================================================================

-- Adicionar coluna is_memorias_vivas à tabela chains
ALTER TABLE public.chains 
ADD COLUMN IF NOT EXISTS is_memorias_vivas BOOLEAN DEFAULT false NOT NULL;

-- Comentário na coluna
COMMENT ON COLUMN public.chains.is_memorias_vivas IS 
'Indica se a corrente pertence ao feed Memórias Vivas (participação restrita a 60+)';

-- ============================================================================
-- ATUALIZAR RLS POLICY DE INSERT PARA POSTS EM CORRENTES
-- ============================================================================

-- Primeiro, vamos verificar e dropar a policy existente de insert para correntes
DROP POLICY IF EXISTS "Usuários podem adicionar posts a correntes" ON public.posts;

-- Criar nova policy que verifica a idade para correntes do Memórias Vivas
CREATE POLICY "Usuários podem adicionar posts a correntes" ON public.posts
AS PERMISSIVE FOR INSERT
WITH CHECK (
    -- Se não for um post de corrente, permitir normalmente
    (chain_id IS NULL)
    OR
    -- Se for um post de corrente, verificar as regras
    (
        chain_id IS NOT NULL
        AND
        (
            -- Se a corrente NÃO for do Memórias Vivas, permitir para todos
            (
                EXISTS (
                    SELECT 1 FROM public.chains 
                    WHERE id = chain_id 
                    AND is_memorias_vivas = false
                )
            )
            OR
            -- Se a corrente FOR do Memórias Vivas, verificar idade
            (
                EXISTS (
                    SELECT 1 FROM public.chains 
                    WHERE id = chain_id 
                    AND is_memorias_vivas = true
                )
                AND
                can_post_in_memorias_vivas(auth.uid())
            )
        )
    )
);

-- ============================================================================
-- FIM DA MIGRAÇÃO
-- ============================================================================
