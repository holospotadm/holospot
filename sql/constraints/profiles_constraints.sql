-- ============================================================================
-- CONSTRAINTS DA TABELA: profiles
-- ============================================================================

ALTER TABLE public.profiles ADD CONSTRAINT 2200_17272_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.profiles ADD CONSTRAINT check_default_feed_values CHECK (((default_feed = ANY (ARRAY['recommended'::text, 'following'::text])) OR (default_feed ~~ 'community-%'::text)));

ALTER TABLE public.profiles ADD CONSTRAINT profiles_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id);

ALTER TABLE public.profiles ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

ALTER TABLE public.profiles ADD CONSTRAINT profiles_username_key UNIQUE (username);

