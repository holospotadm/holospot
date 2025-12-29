-- ============================================================================
-- CONSTRAINTS DA TABELA: user_streaks
-- ============================================================================

ALTER TABLE public.user_streaks ADD CONSTRAINT 2200_33194_1_not_null CHECK (user_id IS NOT NULL);

ALTER TABLE public.user_streaks ADD CONSTRAINT user_streaks_pkey PRIMARY KEY (user_id);

