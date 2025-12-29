-- ============================================================================
-- POLICIES (RLS) DA TABELA: messages
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY Users can mark messages as read ON public.messages AS PERMISSIVE FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.user1_id = auth.uid()) OR (conversations.user2_id = auth.uid())))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.user1_id = auth.uid()) OR (conversations.user2_id = auth.uid()))))));

CREATE POLICY Users can send messages in their conversations ON public.messages AS PERMISSIVE FOR INSERT WITH CHECK (((auth.uid() = sender_id) AND (EXISTS ( SELECT 1
   FROM conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.user1_id = auth.uid()) OR (conversations.user2_id = auth.uid())))))));

CREATE POLICY Users can view messages from their conversations ON public.messages AS PERMISSIVE FOR SELECT USING ((EXISTS ( SELECT 1
   FROM conversations
  WHERE ((conversations.id = messages.conversation_id) AND ((conversations.user1_id = auth.uid()) OR (conversations.user2_id = auth.uid()))))));

