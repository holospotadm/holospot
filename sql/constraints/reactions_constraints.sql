-- ============================================================================
-- CONSTRAINTS DA TABELA: reactions
-- ============================================================================

ALTER TABLE public.reactions ADD CONSTRAINT 2200_17303_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.reactions ADD CONSTRAINT 2200_17303_4_not_null CHECK (type IS NOT NULL);

ALTER TABLE public.reactions ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);

ALTER TABLE public.reactions ADD CONSTRAINT reactions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);

ALTER TABLE public.reactions ADD CONSTRAINT reactions_post_id_user_id_type_key UNIQUE (type, post_id, post_id, user_id, user_id, user_id, type, type, post_id);

ALTER TABLE public.reactions ADD CONSTRAINT reactions_type_check CHECK ((type = ANY (ARRAY['loved'::text, 'claps'::text, 'hug'::text, 'touched'::text, 'grateful'::text, 'inspired'::text])));

ALTER TABLE public.reactions ADD CONSTRAINT reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

