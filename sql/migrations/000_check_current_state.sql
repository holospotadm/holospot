-- ============================================================================
-- VERIFICAÇÃO DO ESTADO ATUAL - Antes de aplicar FKs
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Verificar quais FKs já existem e quais precisam ser criadas
-- ============================================================================

-- 1. Verificar todas as FKs existentes
-- ============================================================================

SELECT 
    'FOREIGN KEYS EXISTENTES:' as info;

SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
    AND tc.table_name IN ('user_points', 'feedbacks')
ORDER BY tc.table_name, tc.constraint_name;

-- 2. Verificar estrutura das tabelas específicas
-- ============================================================================

SELECT 'ESTRUTURA DA TABELA USER_POINTS:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'user_points'
ORDER BY ordinal_position;

SELECT 'ESTRUTURA DA TABELA FEEDBACKS:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'feedbacks'
ORDER BY ordinal_position;

-- 3. Verificar se as tabelas referenciadas existem
-- ============================================================================

SELECT 'VERIFICAÇÃO DE TABELAS REFERENCIADAS:' as info;
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('profiles', 'posts', 'levels') THEN '✅ Existe'
        ELSE '❌ Não existe'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('profiles', 'posts', 'levels')
ORDER BY table_name;

-- 4. Verificar dados específicos que causaram erro
-- ============================================================================

SELECT 'VERIFICAÇÃO DO AUTHOR_ID QUE CAUSOU ERRO:' as info;
SELECT 
    COUNT(*) as total_feedbacks,
    COUNT(DISTINCT author_id) as distinct_authors
FROM feedbacks;

-- Verificar se o author_id específico do erro existe
SELECT 'AUTHOR_ID ESPECÍFICO DO ERRO:' as info;
SELECT 
    f.author_id,
    CASE 
        WHEN p.id IS NOT NULL THEN '✅ Existe em profiles'
        ELSE '❌ NÃO existe em profiles'
    END as status
FROM feedbacks f
LEFT JOIN profiles p ON f.author_id = p.id
WHERE f.author_id = '3157524f-072d-4ee8-a22e-861dcbd05b5f'
LIMIT 1;

-- 5. Verificar integridade geral
-- ============================================================================

SELECT 'VERIFICAÇÃO GERAL DE INTEGRIDADE:' as info;

-- user_points.level_id
SELECT 
    'user_points.level_id' as campo,
    COUNT(*) as total,
    COUNT(CASE WHEN l.id IS NOT NULL THEN 1 END) as validos,
    COUNT(CASE WHEN l.id IS NULL THEN 1 END) as invalidos
FROM user_points up
LEFT JOIN levels l ON up.level_id = l.id;

-- feedbacks.author_id
SELECT 
    'feedbacks.author_id' as campo,
    COUNT(*) as total,
    COUNT(CASE WHEN p.id IS NOT NULL THEN 1 END) as validos,
    COUNT(CASE WHEN p.id IS NULL THEN 1 END) as invalidos
FROM feedbacks f
LEFT JOIN profiles p ON f.author_id = p.id
WHERE f.author_id IS NOT NULL;

-- feedbacks.post_id
SELECT 
    'feedbacks.post_id' as campo,
    COUNT(*) as total,
    COUNT(CASE WHEN po.id IS NOT NULL THEN 1 END) as validos,
    COUNT(CASE WHEN po.id IS NULL THEN 1 END) as invalidos
FROM feedbacks f
LEFT JOIN posts po ON f.post_id = po.id
WHERE f.post_id IS NOT NULL;

-- feedbacks.mentioned_user_id
SELECT 
    'feedbacks.mentioned_user_id' as campo,
    COUNT(*) as total,
    COUNT(CASE WHEN p.id IS NOT NULL THEN 1 END) as validos,
    COUNT(CASE WHEN p.id IS NULL THEN 1 END) as invalidos
FROM feedbacks f
LEFT JOIN profiles p ON f.mentioned_user_id = p.id
WHERE f.mentioned_user_id IS NOT NULL;

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

SELECT 'VERIFICAÇÃO CONCLUÍDA - Analise os resultados acima' as resultado;

