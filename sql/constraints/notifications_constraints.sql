-- ============================================================================
-- CONSTRAINTS DA TABELA: notifications
-- ============================================================================

ALTER TABLE public.notifications ADD CONSTRAINT 2200_17449_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.notifications ADD CONSTRAINT 2200_17449_2_not_null CHECK (user_id IS NOT NULL);

ALTER TABLE public.notifications ADD CONSTRAINT 2200_17449_4_not_null CHECK (type IS NOT NULL);

ALTER TABLE public.notifications ADD CONSTRAINT 2200_17449_5_not_null CHECK (message IS NOT NULL);

ALTER TABLE public.notifications ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);

ALTER TABLE public.notifications ADD CONSTRAINT notifications_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);

