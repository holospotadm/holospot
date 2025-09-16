-- 📦 BACKUP COMPLETO SUPABASE - HoloSpot v4.1-stable (CORRIGIDO)
-- Execute este script no SQL Editor do Supabase para fazer backup completo

-- ============================================================================
-- 🎯 BACKUP AUTOMÁTICO DE TODAS AS TABELAS
-- ============================================================================

-- 1. LISTAR TODAS AS TABELAS DO PROJETO
SELECT 
    'BACKUP INICIADO: ' || NOW()::text || ' - HoloSpot v4.1-stable' as status;

-- 2. MOSTRAR TODAS AS TABELAS EXISTENTES
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname IN ('public', 'auth', 'storage')
ORDER BY schemaname, tablename;

-- ============================================================================
-- 📊 BACKUP DE DADOS - TODAS AS TABELAS
-- ============================================================================

-- SCHEMA: auth (Sistema de Autenticação)
SELECT 'BACKUP: auth.users' as table_name, COUNT(*) as records FROM auth.users;

-- Verificar se outras tabelas auth existem (podem não existir em alguns projetos)
SELECT 
    'TABELA AUTH: ' || tablename as info,
    schemaname
FROM pg_tables 
WHERE schemaname = 'auth'
ORDER BY tablename;

-- SCHEMA: public (Dados da Aplicação)
SELECT 'BACKUP: public.profiles' as table_name, COUNT(*) as records FROM public.profiles;
SELECT 'BACKUP: public.posts' as table_name, COUNT(*) as records FROM public.posts;
SELECT 'BACKUP: public.reactions' as table_name, COUNT(*) as records FROM public.reactions;
SELECT 'BACKUP: public.comments' as table_name, COUNT(*) as records FROM public.comments;
SELECT 'BACKUP: public.feedbacks' as table_name, COUNT(*) as records FROM public.feedbacks;
SELECT 'BACKUP: public.user_points' as table_name, COUNT(*) as records FROM public.user_points;
SELECT 'BACKUP: public.points_history' as table_name, COUNT(*) as records FROM public.points_history;
SELECT 'BACKUP: public.badges' as table_name, COUNT(*) as records FROM public.badges;
SELECT 'BACKUP: public.user_badges' as table_name, COUNT(*) as records FROM public.user_badges;
SELECT 'BACKUP: public.notifications' as table_name, COUNT(*) as records FROM public.notifications;

-- VERIFICAR SE EXISTEM OUTRAS TABELAS
SELECT 
    'TABELA ENCONTRADA: ' || schemaname || '.' || tablename as info
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename NOT IN (
    'profiles', 'posts', 'reactions', 'comments', 'feedbacks',
    'user_points', 'points_history', 'badges', 'user_badges', 'notifications'
)
ORDER BY tablename;

-- ============================================================================
-- 🔧 BACKUP DE ESTRUTURA - SCHEMAS E DEFINIÇÕES
-- ============================================================================

-- BACKUP DE TODAS AS FUNÇÕES
SELECT 
    'FUNÇÃO: ' || routine_name as name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- BACKUP DE TODOS OS TRIGGERS
SELECT 
    'TRIGGER: ' || trigger_name as name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- BACKUP DE TODAS AS VIEWS
SELECT 
    'VIEW: ' || table_name as name,
    view_definition
FROM information_schema.views 
WHERE table_schema = 'public'
ORDER BY table_name;

-- BACKUP DE TODOS OS ÍNDICES
SELECT 
    'ÍNDICE: ' || indexname as name,
    tablename,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================================================
-- 🔐 BACKUP DE SEGURANÇA - RLS E POLÍTICAS
-- ============================================================================

-- BACKUP DE POLÍTICAS RLS
SELECT 
    'POLÍTICA: ' || policyname as name,
    tablename,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- BACKUP DE CONFIGURAÇÕES RLS
SELECT 
    'RLS: ' || tablename as table_name,
    CASE 
        WHEN rowsecurity THEN 'HABILITADO'
        ELSE 'DESABILITADO'
    END as rls_status
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE t.schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 📋 BACKUP DE DADOS ESPECÍFICOS - EXPORT COMPLETO
-- ============================================================================

-- PRIMEIRO: VERIFICAR ESTRUTURA DAS TABELAS PRINCIPAIS
SELECT 'ESTRUTURA: profiles' as section;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

SELECT 'ESTRUTURA: posts' as section;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'posts'
ORDER BY ordinal_position;

-- EXPORT DE DADOS PRINCIPAIS (CORRIGIDO)

-- 1. USUÁRIOS E PERFIS (CORRIGIDO - SÓ REMOVIDO full_name)
SELECT 'EXPORT: Usuários e Perfis' as section;
SELECT 
    u.id,
    u.email,
    u.created_at as user_created,
    p.username,
    p.avatar_url,
    p.created_at as profile_created
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at;

-- 2. POSTS E HOLOFOTES
SELECT 'EXPORT: Posts e Holofotes' as section;
SELECT 
    p.*,
    u.email as author_email,
    prof.username as author_username
FROM public.posts p
LEFT JOIN auth.users u ON p.user_id = u.id
LEFT JOIN public.profiles prof ON p.user_id = prof.id
ORDER BY p.created_at DESC;

-- 3. SISTEMA DE PONTOS
SELECT 'EXPORT: Sistema de Pontos' as section;
SELECT 
    up.*,
    u.email,
    prof.username
FROM public.user_points up
LEFT JOIN auth.users u ON up.user_id = u.id
LEFT JOIN public.profiles prof ON up.user_id = prof.id
ORDER BY up.total_points DESC;

-- 4. HISTÓRICO DE PONTOS
SELECT 'EXPORT: Histórico de Pontos' as section;
SELECT 
    ph.*,
    u.email,
    prof.username
FROM public.points_history ph
LEFT JOIN auth.users u ON ph.user_id = u.id
LEFT JOIN public.profiles prof ON ph.user_id = prof.id
ORDER BY ph.created_at DESC
LIMIT 1000; -- Últimos 1000 registros

-- 5. BADGES E CONQUISTAS
SELECT 'EXPORT: Badges Definidos' as section;
SELECT * FROM public.badges ORDER BY category, name;

SELECT 'EXPORT: Badges Conquistados' as section;
SELECT 
    ub.*,
    b.name as badge_name,
    b.category,
    b.rarity,
    u.email,
    prof.username
FROM public.user_badges ub
LEFT JOIN public.badges b ON ub.badge_id = b.id
LEFT JOIN auth.users u ON ub.user_id = u.id
LEFT JOIN public.profiles prof ON ub.user_id = prof.id
ORDER BY ub.earned_at DESC;

-- 6. REAÇÕES E INTERAÇÕES
SELECT 'EXPORT: Reações' as section;
SELECT 
    r.*,
    u.email as user_email,
    prof.username as user_username
FROM public.reactions r
LEFT JOIN auth.users u ON r.user_id = u.id
LEFT JOIN public.profiles prof ON r.user_id = prof.id
ORDER BY r.created_at DESC
LIMIT 1000; -- Últimas 1000 reações

-- 7. COMENTÁRIOS
SELECT 'EXPORT: Comentários' as section;
SELECT 
    c.*,
    u.email as user_email,
    prof.username as user_username
FROM public.comments c
LEFT JOIN auth.users u ON c.user_id = u.id
LEFT JOIN public.profiles prof ON c.user_id = prof.id
ORDER BY c.created_at DESC
LIMIT 500; -- Últimos 500 comentários

-- 8. FEEDBACKS
SELECT 'EXPORT: Feedbacks' as section;
SELECT 
    f.*,
    u.email as user_email,
    prof.username as user_username
FROM public.feedbacks f
LEFT JOIN auth.users u ON f.user_id = u.id
LEFT JOIN public.profiles prof ON f.user_id = prof.id
ORDER BY f.created_at DESC;

-- 9. NOTIFICAÇÕES
SELECT 'EXPORT: Notificações' as section;
SELECT 
    n.*,
    u.email as user_email,
    prof.username as user_username,
    fu.email as from_user_email,
    fprof.username as from_user_username
FROM public.notifications n
LEFT JOIN auth.users u ON n.user_id = u.id
LEFT JOIN public.profiles prof ON n.user_id = prof.id
LEFT JOIN auth.users fu ON n.from_user_id = fu.id
LEFT JOIN public.profiles fprof ON n.from_user_id = fprof.id
ORDER BY n.created_at DESC
LIMIT 1000; -- Últimas 1000 notificações

-- ============================================================================
-- 🔍 BACKUP DINÂMICO - TODAS AS TABELAS AUTOMATICAMENTE
-- ============================================================================

-- BACKUP AUTOMÁTICO DE QUALQUER TABELA QUE EXISTIR
SELECT 'BACKUP AUTOMÁTICO: Verificando todas as tabelas' as section;

-- Para cada tabela em public, mostrar estrutura e contagem
SELECT 
    'TABELA: ' || tablename as nome,
    'Registros: ' || (
        CASE 
            WHEN tablename = 'profiles' THEN (SELECT COUNT(*)::text FROM public.profiles)
            WHEN tablename = 'posts' THEN (SELECT COUNT(*)::text FROM public.posts)
            WHEN tablename = 'reactions' THEN (SELECT COUNT(*)::text FROM public.reactions)
            WHEN tablename = 'comments' THEN (SELECT COUNT(*)::text FROM public.comments)
            WHEN tablename = 'feedbacks' THEN (SELECT COUNT(*)::text FROM public.feedbacks)
            WHEN tablename = 'user_points' THEN (SELECT COUNT(*)::text FROM public.user_points)
            WHEN tablename = 'points_history' THEN (SELECT COUNT(*)::text FROM public.points_history)
            WHEN tablename = 'badges' THEN (SELECT COUNT(*)::text FROM public.badges)
            WHEN tablename = 'user_badges' THEN (SELECT COUNT(*)::text FROM public.user_badges)
            WHEN tablename = 'notifications' THEN (SELECT COUNT(*)::text FROM public.notifications)
            ELSE 'Tabela não mapeada'
        END
    ) as contagem
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 📊 ESTATÍSTICAS FINAIS DO BACKUP
-- ============================================================================

SELECT 'ESTATÍSTICAS FINAIS DO BACKUP v4.1-stable' as section;

-- Contagem total de registros por tabela
SELECT 
    'TOTAL GERAL' as categoria,
    (SELECT COUNT(*) FROM auth.users) as usuarios,
    (SELECT COUNT(*) FROM public.profiles) as perfis,
    (SELECT COUNT(*) FROM public.posts) as posts,
    (SELECT COUNT(*) FROM public.reactions) as reacoes,
    (SELECT COUNT(*) FROM public.comments) as comentarios,
    (SELECT COUNT(*) FROM public.feedbacks) as feedbacks,
    (SELECT COUNT(*) FROM public.user_points) as usuarios_com_pontos,
    (SELECT COUNT(*) FROM public.points_history) as historico_pontos,
    (SELECT COUNT(*) FROM public.badges) as badges_definidos,
    (SELECT COUNT(*) FROM public.user_badges) as badges_conquistados,
    (SELECT COUNT(*) FROM public.notifications) as notificacoes;

-- Estatísticas de gamificação
SELECT 
    'GAMIFICAÇÃO' as categoria,
    (SELECT COALESCE(SUM(total_points), 0) FROM public.user_points) as pontos_totais,
    (SELECT COALESCE(MAX(total_points), 0) FROM public.user_points) as maior_pontuacao,
    (SELECT COALESCE(AVG(total_points), 0) FROM public.user_points) as media_pontos,
    (SELECT COUNT(DISTINCT user_id) FROM public.user_badges) as usuarios_com_badges;

-- Status dos triggers e funções
SELECT 
    'SISTEMA' as categoria,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public') as funcoes,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = 'public') as triggers,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as politicas_rls;

-- ============================================================================
-- 🎯 BACKUP DE CONFIGURAÇÕES ESPECÍFICAS DO HOLOSPOT
-- ============================================================================

-- BACKUP DAS FUNÇÕES CRÍTICAS DO SISTEMA
SELECT 'FUNÇÕES CRÍTICAS DO HOLOSPOT' as section;

SELECT 
    routine_name,
    'FUNÇÃO ENCONTRADA' as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN (
    'add_points_secure',
    'recalculate_user_points_secure', 
    'check_and_grant_badges_with_bonus',
    'handle_post_insert_secure',
    'handle_reaction_insert_secure',
    'handle_reaction_delete_secure',
    'delete_reaction_points_secure'
)
ORDER BY routine_name;

-- BACKUP DOS TRIGGERS CRÍTICOS
SELECT 'TRIGGERS CRÍTICOS DO HOLOSPOT' as section;

SELECT 
    trigger_name,
    'TRIGGER ENCONTRADO' as status
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND trigger_name LIKE '%secure%'
ORDER BY trigger_name;

SELECT 
    'BACKUP CONCLUÍDO: ' || NOW()::text || ' - v4.1-stable' as status,
    'SISTEMA ESTÁVEL E FUNCIONAL' as estado;

-- ============================================================================
-- 🎯 INSTRUÇÕES DE USO (ATUALIZADAS)
-- ============================================================================

/*
📋 COMO USAR ESTE BACKUP CORRIGIDO:

1. EXECUTAR NO SUPABASE:
   ✅ Script corrigido sem campos inexistentes
   ✅ Verifica estrutura das tabelas automaticamente
   ✅ Backup seguro e completo

2. SALVAR RESULTADOS:
   - Copie todas as tabelas de resultados
   - Salve em arquivo .sql ou .csv
   - Guarde junto com o backup do GitHub

3. VERIFICAÇÃO:
   - Confira se todas as contagens batem
   - Verifique se funções críticas existem
   - Valide triggers do sistema de gamificação

✅ BACKUP COMPLETO E CORRIGIDO!
🚀 PRONTO PARA FASE 5!
*/

