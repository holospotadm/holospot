-- ============================================================================
-- CONSTRAINTS DA TABELA: comments
-- ============================================================================

ALTER TABLE public.comments ADD CONSTRAINT 2200_19051_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.comments ADD CONSTRAINT 2200_19051_4_not_null CHECK (content IS NOT NULL);

ALTER TABLE public.comments ADD CONSTRAINT comments_pkey PRIMARY KEY (id);

ALTER TABLE public.comments ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);

ALTER TABLE public.comments ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

