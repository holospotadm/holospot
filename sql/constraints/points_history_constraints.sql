-- ============================================================================
-- CONSTRAINTS DA TABELA: points_history
-- ============================================================================

ALTER TABLE public.points_history ADD CONSTRAINT 2200_30341_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.points_history ADD CONSTRAINT 2200_30341_2_not_null CHECK (user_id IS NOT NULL);

ALTER TABLE public.points_history ADD CONSTRAINT 2200_30341_3_not_null CHECK (action_type IS NOT NULL);

ALTER TABLE public.points_history ADD CONSTRAINT 2200_30341_4_not_null CHECK (points_earned IS NOT NULL);

ALTER TABLE public.points_history ADD CONSTRAINT points_history_pkey PRIMARY KEY (id);

