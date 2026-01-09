-- ============================================================================
-- POLICIES (RLS) DA TABELA: chain_posts
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.chain_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY Autor pode deletar seu post da corrente ON public.chain_posts AS PERMISSIVE FOR DELETE USING ((auth.uid() = author_id));

CREATE POLICY Posts de correntes são públicos ON public.chain_posts AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY Usuários autenticados podem adicionar posts a correntes ativas ON public.chain_posts AS PERMISSIVE FOR INSERT WITH CHECK (
    (auth.uid() = author_id) 
    AND 
    (
        EXISTS (
            SELECT 1
            FROM chains
            WHERE chains.id = chain_posts.chain_id 
            AND chains.status = 'active'::text
            AND (
                -- Se não for corrente do Memórias Vivas, permitir para todos
                chains.is_memorias_vivas = false
                OR
                -- Se for corrente do Memórias Vivas, verificar idade
                (chains.is_memorias_vivas = true AND can_post_in_memorias_vivas(auth.uid()))
            )
        )
    )
);

