-- ============================================================================
-- POLICIES (RLS) DA TABELA: user_streaks
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY Users can update own streak ON public.user_streaks AS PERMISSIVE FOR ALL USING ((auth.uid() = user_id));

CREATE POLICY Users can view own streak ON public.user_streaks AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

CREATE POLICY user_streaks_insert_policy ON public.user_streaks AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY user_streaks_select_policy ON public.user_streaks AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

CREATE POLICY user_streaks_update_policy ON public.user_streaks AS PERMISSIVE FOR UPDATE USING (true);

