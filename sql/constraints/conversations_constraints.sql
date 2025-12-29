-- ============================================================================
-- CONSTRAINTS DA TABELA: conversations
-- ============================================================================

ALTER TABLE public.conversations ADD CONSTRAINT 2200_75253_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.conversations ADD CONSTRAINT 2200_75253_2_not_null CHECK (user1_id IS NOT NULL);

ALTER TABLE public.conversations ADD CONSTRAINT 2200_75253_3_not_null CHECK (user2_id IS NOT NULL);

ALTER TABLE public.conversations ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);

ALTER TABLE public.conversations ADD CONSTRAINT conversations_unique_pair UNIQUE (user2_id, user2_id, user1_id, user1_id);

ALTER TABLE public.conversations ADD CONSTRAINT conversations_user_order CHECK ((user1_id < user2_id));

