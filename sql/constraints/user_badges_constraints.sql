-- ============================================================================
-- CONSTRAINTS DA TABELA: user_badges
-- ============================================================================

ALTER TABLE public.user_badges ADD CONSTRAINT 2200_30302_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.user_badges ADD CONSTRAINT 2200_30302_2_not_null CHECK (user_id IS NOT NULL);

ALTER TABLE public.user_badges ADD CONSTRAINT 2200_30302_3_not_null CHECK (badge_id IS NOT NULL);

ALTER TABLE public.user_badges ADD CONSTRAINT user_badges_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badges(id);

ALTER TABLE public.user_badges ADD CONSTRAINT user_badges_pkey PRIMARY KEY (id);

ALTER TABLE public.user_badges ADD CONSTRAINT user_badges_user_id_badge_id_key UNIQUE (user_id, badge_id, user_id, badge_id);

