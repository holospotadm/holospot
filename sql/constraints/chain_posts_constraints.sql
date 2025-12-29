-- ============================================================================
-- CONSTRAINTS DA TABELA: chain_posts
-- ============================================================================

ALTER TABLE public.chain_posts ADD CONSTRAINT 2200_101391_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.chain_posts ADD CONSTRAINT 2200_101391_2_not_null CHECK (chain_id IS NOT NULL);

ALTER TABLE public.chain_posts ADD CONSTRAINT 2200_101391_3_not_null CHECK (post_id IS NOT NULL);

ALTER TABLE public.chain_posts ADD CONSTRAINT 2200_101391_4_not_null CHECK (author_id IS NOT NULL);

ALTER TABLE public.chain_posts ADD CONSTRAINT 2200_101391_6_not_null CHECK (created_at IS NOT NULL);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_chain_id_fkey FOREIGN KEY (chain_id) REFERENCES public.chains(id);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_parent_post_author_id_fkey FOREIGN KEY (parent_post_author_id) REFERENCES public.profiles(id);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_pkey PRIMARY KEY (id);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);

ALTER TABLE public.chain_posts ADD CONSTRAINT chain_posts_post_id_key UNIQUE (post_id);

