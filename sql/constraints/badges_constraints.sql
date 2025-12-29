-- ============================================================================
-- CONSTRAINTS DA TABELA: badges
-- ============================================================================

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_2_not_null CHECK (name IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_3_not_null CHECK (description IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_4_not_null CHECK (icon IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_5_not_null CHECK (category IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_7_not_null CHECK (condition_type IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT 2200_30287_8_not_null CHECK (condition_value IS NOT NULL);

ALTER TABLE public.badges ADD CONSTRAINT badges_name_key UNIQUE (name);

ALTER TABLE public.badges ADD CONSTRAINT badges_pkey PRIMARY KEY (id);

