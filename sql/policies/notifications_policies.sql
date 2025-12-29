-- ============================================================================
-- POLICIES (RLS) DA TABELA: notifications
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY Sistema pode criar notificações ON public.notifications AS PERMISSIVE FOR INSERT WITH CHECK (true);

CREATE POLICY Usuários podem atualizar suas notificações ON public.notifications AS PERMISSIVE FOR UPDATE USING ((auth.uid() = user_id));

CREATE POLICY Usuários veem apenas suas notificações ON public.notifications AS PERMISSIVE FOR SELECT USING ((auth.uid() = user_id));

