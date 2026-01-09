-- ============================================================================
-- CONSTRAINTS DA TABELA: chains
-- ============================================================================

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_2_not_null CHECK (created_at IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_3_not_null CHECK (creator_id IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_4_not_null CHECK (name IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_5_not_null CHECK (description IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_6_not_null CHECK (highlight_type IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_7_not_null CHECK (status IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT 2200_101360_8_not_null CHECK (is_memorias_vivas IS NOT NULL);

ALTER TABLE public.chains ADD CONSTRAINT chains_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.profiles(id);

ALTER TABLE public.chains ADD CONSTRAINT chains_description_check CHECK (((char_length(description) >= 10) AND (char_length(description) <= 200)));

ALTER TABLE public.chains ADD CONSTRAINT chains_first_post_id_fkey FOREIGN KEY (first_post_id) REFERENCES public.posts(id);

ALTER TABLE public.chains ADD CONSTRAINT chains_name_check CHECK (((char_length(name) >= 3) AND (char_length(name) <= 50)));

ALTER TABLE public.chains ADD CONSTRAINT chains_pkey PRIMARY KEY (id);

ALTER TABLE public.chains ADD CONSTRAINT chains_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'closed'::text])));

