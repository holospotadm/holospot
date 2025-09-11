-- =====================================================
-- CORRIGIR PERMISSÕES RLS PARA NOVOS CAMPOS
-- =====================================================

-- 1. VERIFICAR POLÍTICAS ATUAIS DA TABELA points_history
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'points_history';

-- 2. VERIFICAR SE RLS ESTÁ HABILITADO
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('points_history', 'reactions');

-- 3. DESABILITAR RLS TEMPORARIAMENTE PARA TESTAR (CUIDADO!)
-- ALTER TABLE public.points_history DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.reactions DISABLE ROW LEVEL SECURITY;

-- 4. OU CRIAR/ATUALIZAR POLÍTICAS MAIS PERMISSIVAS

-- Política para permitir inserção na points_history
DROP POLICY IF EXISTS "points_history_insert_policy" ON public.points_history;
CREATE POLICY "points_history_insert_policy" 
ON public.points_history 
FOR INSERT 
WITH CHECK (true);

-- Política para permitir seleção na points_history
DROP POLICY IF EXISTS "points_history_select_policy" ON public.points_history;
CREATE POLICY "points_history_select_policy" 
ON public.points_history 
FOR SELECT 
USING (true);

-- Política para permitir inserção na reactions
DROP POLICY IF EXISTS "reactions_insert_policy" ON public.reactions;
CREATE POLICY "reactions_insert_policy" 
ON public.reactions 
FOR INSERT 
WITH CHECK (true);

-- Política para permitir seleção na reactions
DROP POLICY IF EXISTS "reactions_select_policy" ON public.reactions;
CREATE POLICY "reactions_select_policy" 
ON public.reactions 
FOR SELECT 
USING (true);

-- Política para permitir deleção na reactions
DROP POLICY IF EXISTS "reactions_delete_policy" ON public.reactions;
CREATE POLICY "reactions_delete_policy" 
ON public.reactions 
FOR DELETE 
USING (true);

-- 5. VERIFICAR SE AS POLÍTICAS FORAM CRIADAS
SELECT 
    'POLÍTICAS ATUALIZADAS' as status,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename IN ('points_history', 'reactions');

-- 6. TESTAR INSERÇÃO MANUAL (PARA DEBUG)
-- INSERT INTO public.points_history (
--     user_id, 
--     action_type, 
--     points_earned, 
--     reference_id, 
--     reference_type,
--     post_id,
--     reaction_type,
--     reaction_user_id,
--     created_at
-- ) VALUES (
--     '91538487-e08e-49e4-a630-0e41b8541d40',
--     'reaction_given',
--     2,
--     gen_random_uuid(),
--     'reaction',
--     'cd297715-8cb4-411c-99f7-33406a22d811',
--     'touched',
--     NULL,
--     NOW()
-- );

SELECT 'Permissões RLS atualizadas para suportar novos campos' as resultado;

