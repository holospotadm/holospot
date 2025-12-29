-- ============================================================================
-- POLICIES (RLS) DA TABELA: profiles
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY Users can view all profiles ON public.profiles AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY profiles_insert_policy ON public.profiles AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY profiles_select_policy ON public.profiles AS PERMISSIVE FOR SELECT USING (true);

CREATE POLICY profiles_update_policy ON public.profiles AS PERMISSIVE FOR UPDATE USING (true);

