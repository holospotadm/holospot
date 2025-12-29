-- ============================================================================
-- CONSTRAINTS DA TABELA: feedbacks
-- ============================================================================

ALTER TABLE public.feedbacks ADD CONSTRAINT 2200_17694_1_not_null CHECK (id IS NOT NULL);

ALTER TABLE public.feedbacks ADD CONSTRAINT 2200_17694_2_not_null CHECK (created_at IS NOT NULL);

ALTER TABLE public.feedbacks ADD CONSTRAINT feedbacks_pkey PRIMARY KEY (id);

ALTER TABLE public.feedbacks ADD CONSTRAINT fk_feedbacks_author FOREIGN KEY (author_id) REFERENCES public.profiles(id);

ALTER TABLE public.feedbacks ADD CONSTRAINT fk_feedbacks_mentioned_user FOREIGN KEY (mentioned_user_id) REFERENCES public.profiles(id);

ALTER TABLE public.feedbacks ADD CONSTRAINT fk_feedbacks_post FOREIGN KEY (post_id) REFERENCES public.posts(id);

