-- =====================================================
-- INVESTIGAR TABELA posts_with_reactions - ESTRUTURA PRIMEIRO
-- =====================================================

-- 1. VERIFICAR ESTRUTURA DA TABELA (EXECUTAR PRIMEIRO)
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'posts_with_reactions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VERIFICAR REGISTROS RECENTES (EXECUTAR APÓS VER ESTRUTURA)
SELECT *
FROM public.posts_with_reactions
ORDER BY created_at DESC
LIMIT 10;

-- 3. VERIFICAR SE HÁ TRIGGERS QUE ALIMENTAM ESTA TABELA
SELECT 
    t.tgname as trigger_name,
    c.relname as table_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
AND (c.relname IN ('posts', 'reactions') OR t.tgname ILIKE '%posts_with_reactions%')
AND NOT t.tgisinternal;

-- 4. VERIFICAR VIEWS QUE USAM ESTA TABELA
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
AND definition ILIKE '%posts_with_reactions%';

-- 5. VERIFICAR FUNÇÕES QUE USAM ESTA TABELA
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_definition ILIKE '%posts_with_reactions%';

-- EXECUTAR APENAS AS QUERIES ACIMA PRIMEIRO
-- Depois que soubermos a estrutura, podemos fazer queries mais específicas

