-- ============================================================================
-- TABELA: feedbacks
-- ============================================================================

CREATE TABLE public.feedbacks (id bigint NOT NULL, created_at timestamp with time zone NOT NULL DEFAULT now(), post_id uuid DEFAULT gen_random_uuid(), author_id uuid DEFAULT gen_random_uuid(), feedback_text text, mentioned_user_id uuid);
