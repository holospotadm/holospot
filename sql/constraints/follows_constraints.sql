-- ============================================================================
-- CONSTRAINTS DA TABELA: follows
-- ============================================================================

ALTER TABLE public.follows ADD CONSTRAINT 2200_17429_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.follows ADD CONSTRAINT 2200_17429_2_not_null CHECK (follower_id IS NOT NULL);

ALTER TABLE public.follows ADD CONSTRAINT 2200_17429_3_not_null CHECK (following_id IS NOT NULL);

ALTER TABLE public.follows ADD CONSTRAINT follows_check CHECK ((follower_id <> following_id));

ALTER TABLE public.follows ADD CONSTRAINT follows_follower_id_following_id_key UNIQUE (follower_id, following_id, follower_id, following_id);

ALTER TABLE public.follows ADD CONSTRAINT follows_pkey PRIMARY KEY (id);

