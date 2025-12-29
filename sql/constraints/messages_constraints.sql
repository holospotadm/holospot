-- ============================================================================
-- CONSTRAINTS DA TABELA: messages
-- ============================================================================

ALTER TABLE public.messages ADD CONSTRAINT 2200_75279_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.messages ADD CONSTRAINT 2200_75279_2_not_null CHECK (conversation_id IS NOT NULL);

ALTER TABLE public.messages ADD CONSTRAINT 2200_75279_3_not_null CHECK (sender_id IS NOT NULL);

ALTER TABLE public.messages ADD CONSTRAINT 2200_75279_4_not_null CHECK (content IS NOT NULL);

ALTER TABLE public.messages ADD CONSTRAINT messages_content_not_empty CHECK ((length(TRIM(BOTH FROM content)) > 0));

ALTER TABLE public.messages ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);

ALTER TABLE public.messages ADD CONSTRAINT messages_pkey PRIMARY KEY (id);

