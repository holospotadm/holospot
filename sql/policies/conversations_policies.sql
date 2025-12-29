-- ============================================================================
-- POLICIES (RLS) DA TABELA: conversations
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY Users can create conversations ON public.conversations AS PERMISSIVE FOR INSERT WITH CHECK (((auth.uid() = user1_id) OR (auth.uid() = user2_id)));

CREATE POLICY Users can view their own conversations ON public.conversations AS PERMISSIVE FOR SELECT USING (((auth.uid() = user1_id) OR (auth.uid() = user2_id)));

