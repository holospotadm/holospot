-- ============================================================================
-- CONSTRAINTS DA TABELA: posts
-- ============================================================================

ALTER TABLE public.posts ADD CONSTRAINT 2200_17286_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.posts ADD CONSTRAINT 2200_17286_3_not_null CHECK (celebrated_person_name IS NOT NULL);

ALTER TABLE public.posts ADD CONSTRAINT 2200_17286_4_not_null CHECK (content IS NOT NULL);

ALTER TABLE public.posts ADD CONSTRAINT posts_chain_id_fkey FOREIGN KEY (chain_id) REFERENCES public.chains(id);

ALTER TABLE public.posts ADD CONSTRAINT posts_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id);

ALTER TABLE public.posts ADD CONSTRAINT posts_pkey PRIMARY KEY (id);

ALTER TABLE public.posts ADD CONSTRAINT posts_type_check CHECK ((type = ANY (ARRAY['gratitude'::text, 'achievement'::text, 'memory'::text, 'inspiration'::text, 'support'::text, 'admiration'::text])));

ALTER TABLE public.posts ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

