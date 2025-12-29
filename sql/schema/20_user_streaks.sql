-- ============================================================================
-- TABELA: user_streaks
-- ============================================================================

CREATE TABLE public.user_streaks (last_activity_date date, longest_streak integer DEFAULT 0, user_id uuid NOT NULL, current_streak integer DEFAULT 0, next_milestone integer DEFAULT 7, updated_at timestamp without time zone DEFAULT now());
