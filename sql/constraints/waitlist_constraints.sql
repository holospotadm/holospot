-- ============================================================================
-- CONSTRAINTS DA TABELA: waitlist
-- ============================================================================

ALTER TABLE public.waitlist ADD CONSTRAINT 2200_114415_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.waitlist ADD CONSTRAINT 2200_114415_2_not_null CHECK (email IS NOT NULL);

ALTER TABLE public.waitlist ADD CONSTRAINT waitlist_email_key UNIQUE (email);

ALTER TABLE public.waitlist ADD CONSTRAINT waitlist_pkey PRIMARY KEY (id);

