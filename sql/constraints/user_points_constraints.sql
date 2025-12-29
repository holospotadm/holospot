-- ============================================================================
-- CONSTRAINTS DA TABELA: user_points
-- ============================================================================

ALTER TABLE public.user_points ADD CONSTRAINT 2200_30323_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.user_points ADD CONSTRAINT 2200_30323_2_not_null CHECK (user_id IS NOT NULL);

ALTER TABLE public.user_points ADD CONSTRAINT fk_user_points_level FOREIGN KEY (level_id) REFERENCES public.levels(id);

ALTER TABLE public.user_points ADD CONSTRAINT user_points_pkey PRIMARY KEY (id);

ALTER TABLE public.user_points ADD CONSTRAINT user_points_user_id_key UNIQUE (user_id);

