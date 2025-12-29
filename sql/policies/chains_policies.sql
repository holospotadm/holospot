-- ============================================================================
-- POLICIES (RLS) DA TABELA: chains
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.chains ENABLE ROW LEVEL SECURITY;

CREATE POLICY Correntes ativas e fechadas são públicas ON public.chains AS PERMISSIVE FOR SELECT USING ((status = ANY (ARRAY['active'::text, 'closed'::text])));

CREATE POLICY Criador pode atualizar sua corrente ON public.chains AS PERMISSIVE FOR UPDATE USING ((auth.uid() = creator_id)) WITH CHECK ((auth.uid() = creator_id));

CREATE POLICY Criador pode deletar corrente pendente ON public.chains AS PERMISSIVE FOR DELETE USING (((auth.uid() = creator_id) AND (status = 'pending'::text)));

CREATE POLICY Criador pode ver suas correntes pendentes ON public.chains AS PERMISSIVE FOR SELECT USING ((auth.uid() = creator_id));

CREATE POLICY Usuários autenticados podem criar correntes ON public.chains AS PERMISSIVE FOR INSERT WITH CHECK ((auth.uid() = creator_id));

