-- ============================================================================
-- CONSTRAINTS DA TABELA: communities
-- ============================================================================

ALTER TABLE public.communities ADD CONSTRAINT 2200_75394_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.communities ADD CONSTRAINT 2200_75394_2_not_null CHECK (name IS NOT NULL);

ALTER TABLE public.communities ADD CONSTRAINT 2200_75394_3_not_null CHECK (slug IS NOT NULL);

ALTER TABLE public.communities ADD CONSTRAINT 2200_75394_7_not_null CHECK (owner_id IS NOT NULL);

ALTER TABLE public.communities ADD CONSTRAINT communities_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id);

ALTER TABLE public.communities ADD CONSTRAINT communities_pkey PRIMARY KEY (id);

ALTER TABLE public.communities ADD CONSTRAINT communities_slug_key UNIQUE (slug);

ALTER TABLE public.communities ADD CONSTRAINT communities_slug_unique UNIQUE (slug);

