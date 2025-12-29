-- ============================================================================
-- CONSTRAINTS DA TABELA: community_members
-- ============================================================================

ALTER TABLE public.community_members ADD CONSTRAINT 2200_75416_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.community_members ADD CONSTRAINT community_members_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id);

ALTER TABLE public.community_members ADD CONSTRAINT community_members_community_id_user_id_key UNIQUE (community_id, user_id, user_id, community_id);

ALTER TABLE public.community_members ADD CONSTRAINT community_members_pkey PRIMARY KEY (id);

ALTER TABLE public.community_members ADD CONSTRAINT community_members_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'member'::text])));

ALTER TABLE public.community_members ADD CONSTRAINT community_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id);

