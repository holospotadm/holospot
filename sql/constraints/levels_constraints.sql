-- ============================================================================
-- CONSTRAINTS DA TABELA: levels
-- ============================================================================

ALTER TABLE public.levels ADD CONSTRAINT 2200_30353_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.levels ADD CONSTRAINT 2200_30353_2_not_null CHECK (name IS NOT NULL);

ALTER TABLE public.levels ADD CONSTRAINT 2200_30353_3_not_null CHECK (points_required IS NOT NULL);

ALTER TABLE public.levels ADD CONSTRAINT 2200_30353_4_not_null CHECK (icon IS NOT NULL);

ALTER TABLE public.levels ADD CONSTRAINT 2200_30353_5_not_null CHECK (color IS NOT NULL);

ALTER TABLE public.levels ADD CONSTRAINT levels_pkey PRIMARY KEY (id);

