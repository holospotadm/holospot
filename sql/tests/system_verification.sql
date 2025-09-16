-- 🔍 VERIFICAÇÃO COMPLETA: Funções, triggers e versões atuais do sistema
-- Mostra estado atual de todo o sistema de notificações e gamificação

-- ============================================================================
-- 📋 INFORMAÇÕES GERAIS DO SISTEMA
-- ============================================================================

SELECT 
    '🔍 VERIFICAÇÃO COMPLETA DO SISTEMA' as titulo,
    'Data/Hora: ' || NOW()::text as timestamp,
    'Versão PostgreSQL: ' || version() as versao_db;

-- ============================================================================
-- 🔧 FUNÇÕES: Todas as funções customizadas
-- ============================================================================

SELECT 
    '📋 FUNÇÕES CUSTOMIZADAS' as secao,
    routine_name as nome_funcao,
    routine_type as tipo,
    CASE 
        WHEN routine_name LIKE '%notification%' THEN 'NOTIFICAÇÕES'
        WHEN routine_name LIKE '%gamification%' THEN 'GAMIFICAÇÃO'
        WHEN routine_name LIKE '%points%' THEN 'PONTOS'
        WHEN routine_name LIKE '%badge%' THEN 'BADGES'
        WHEN routine_name LIKE '%streak%' THEN 'STREAK'
        WHEN routine_name LIKE '%feedback%' THEN 'FEEDBACK'
        WHEN routine_name LIKE '%comment%' THEN 'COMENTÁRIOS'
        WHEN routine_name LIKE '%reaction%' THEN 'REAÇÕES'
        WHEN routine_name LIKE '%follow%' THEN 'FOLLOWS'
        WHEN routine_name LIKE '%holofote%' THEN 'HOLOFOTES'
        ELSE 'OUTROS'
    END as categoria,
    external_language as linguagem,
    created as criado_em
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name NOT LIKE 'pg_%'
AND routine_name NOT LIKE 'st_%'
ORDER BY categoria, routine_name;

-- ============================================================================
-- ⚡ TRIGGERS: Todos os triggers ativos
-- ============================================================================

SELECT 
    '⚡ TRIGGERS ATIVOS' as secao,
    trigger_name as nome_trigger,
    event_object_table as tabela,
    event_manipulation as evento,
    action_timing as timing,
    action_statement as funcao_executada,
    CASE 
        WHEN trigger_name LIKE '%notification%' THEN 'NOTIFICAÇÕES'
        WHEN trigger_name LIKE '%gamification%' THEN 'GAMIFICAÇÃO'
        WHEN trigger_name LIKE '%points%' THEN 'PONTOS'
        WHEN trigger_name LIKE '%badge%' THEN 'BADGES'
        WHEN trigger_name LIKE '%streak%' THEN 'STREAK'
        WHEN trigger_name LIKE '%feedback%' THEN 'FEEDBACK'
        WHEN trigger_name LIKE '%comment%' THEN 'COMENTÁRIOS'
        WHEN trigger_name LIKE '%reaction%' THEN 'REAÇÕES'
        WHEN trigger_name LIKE '%follow%' THEN 'FOLLOWS'
        WHEN trigger_name LIKE '%holofote%' THEN 'HOLOFOTES'
        ELSE 'OUTROS'
    END as categoria
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY categoria, event_object_table, trigger_name;

-- ============================================================================
-- 📊 ESTATÍSTICAS: Contadores do sistema
-- ============================================================================

-- Contadores de notificações por tipo
SELECT 
    '📊 NOTIFICAÇÕES POR TIPO' as secao,
    type as tipo,
    COUNT(*) as total,
    COUNT(CASE WHEN read = false THEN 1 END) as nao_lidas,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '24 hours' THEN 1 END) as ultimas_24h,
    MAX(created_at) as mais_recente
FROM public.notifications 
GROUP BY type
ORDER BY total DESC;

-- Contadores de pontos por ação
SELECT 
    '📊 PONTOS POR AÇÃO' as secao,
    action_type as tipo_acao,
    COUNT(*) as total_acoes,
    SUM(points_earned) as total_pontos,
    AVG(points_earned) as media_pontos,
    MAX(created_at) as mais_recente
FROM public.points_history 
GROUP BY action_type
ORDER BY total_pontos DESC;

-- Contadores de badges
SELECT 
    '📊 BADGES CONQUISTADOS' as secao,
    badge_id,
    COUNT(*) as total_conquistados,
    MAX(earned_at) as mais_recente
FROM public.user_badges 
GROUP BY badge_id
ORDER BY total_conquistados DESC;

-- ============================================================================
-- 🔍 VERIFICAÇÕES DE INTEGRIDADE
-- ============================================================================

-- Verificar duplicatas em notificações
SELECT 
    '🔍 DUPLICATAS EM NOTIFICAÇÕES' as verificacao,
    COUNT(*) as total_duplicatas
FROM (
    SELECT user_id, from_user_id, type, message, COUNT(*) as duplicatas
    FROM public.notifications 
    WHERE created_at > NOW() - INTERVAL '24 hours'
    GROUP BY user_id, from_user_id, type, message
    HAVING COUNT(*) > 1
) duplicatas;

-- Verificar inconsistências em pontos
SELECT 
    '🔍 INCONSISTÊNCIAS EM PONTOS' as verificacao,
    COUNT(*) as usuarios_com_inconsistencia
FROM (
    SELECT 
        up.user_id,
        up.total_points as pontos_tabela,
        COALESCE(SUM(ph.points_earned), 0) as pontos_historico,
        up.total_points - COALESCE(SUM(ph.points_earned), 0) as diferenca
    FROM public.user_points up
    LEFT JOIN public.points_history ph ON ph.user_id = up.user_id
    GROUP BY up.user_id, up.total_points
    HAVING up.total_points != COALESCE(SUM(ph.points_earned), 0)
) inconsistencias;

-- ============================================================================
-- 📋 ESTRUTURA DAS TABELAS PRINCIPAIS
-- ============================================================================

-- Estrutura da tabela notifications
SELECT 
    '📋 ESTRUTURA: notifications' as tabela,
    column_name as campo,
    data_type as tipo,
    is_nullable as permite_null,
    column_default as valor_padrao
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'notifications'
ORDER BY ordinal_position;

-- Estrutura da tabela feedbacks
SELECT 
    '📋 ESTRUTURA: feedbacks' as tabela,
    column_name as campo,
    data_type as tipo,
    is_nullable as permite_null,
    column_default as valor_padrao
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'feedbacks'
ORDER BY ordinal_position;

-- Estrutura da tabela posts (para holofotes)
SELECT 
    '📋 ESTRUTURA: posts' as tabela,
    column_name as campo,
    data_type as tipo,
    is_nullable as permite_null,
    CASE 
        WHEN column_name = 'mentioned_user_id' THEN '← CAMPO PARA HOLOFOTES'
        WHEN column_name = 'user_id' THEN '← AUTOR DO POST'
        WHEN column_name = 'content' THEN '← CONTEÚDO DO POST'
        ELSE ''
    END as observacao
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'posts'
ORDER BY ordinal_position;

-- ============================================================================
-- 🧪 TESTES DE FUNCIONAMENTO
-- ============================================================================

-- Verificar se triggers estão respondendo
SELECT 
    '🧪 TESTE: Triggers por tabela' as teste,
    event_object_table as tabela,
    COUNT(*) as total_triggers,
    STRING_AGG(trigger_name, ', ') as nomes_triggers
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('notifications', 'feedbacks', 'comments', 'reactions', 'follows', 'posts', 'user_badges', 'user_points')
GROUP BY event_object_table
ORDER BY event_object_table;

-- Verificar últimas atividades
SELECT 
    '🧪 ÚLTIMAS ATIVIDADES' as teste,
    'Última notificação: ' || MAX(created_at)::text as ultima_notificacao
FROM public.notifications
UNION ALL
SELECT 
    '🧪 ÚLTIMAS ATIVIDADES' as teste,
    'Último ponto: ' || MAX(created_at)::text as ultimo_ponto
FROM public.points_history
UNION ALL
SELECT 
    '🧪 ÚLTIMAS ATIVIDADES' as teste,
    'Último badge: ' || MAX(earned_at)::text as ultimo_badge
FROM public.user_badges;

-- ============================================================================
-- 📊 RESUMO FINAL
-- ============================================================================

SELECT 
    '📊 RESUMO FINAL DO SISTEMA' as status,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name NOT LIKE 'pg_%' AND routine_name NOT LIKE 'st_%') || ' funções customizadas' as funcoes,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema = 'public') || ' triggers ativos' as triggers,
    (SELECT COUNT(*) FROM public.notifications WHERE created_at > NOW() - INTERVAL '24 hours') || ' notificações (24h)' as notificacoes_recentes,
    (SELECT COUNT(*) FROM public.points_history WHERE created_at > NOW() - INTERVAL '24 hours') || ' pontos (24h)' as pontos_recentes,
    (SELECT COUNT(*) FROM public.user_badges WHERE earned_at > NOW() - INTERVAL '24 hours') || ' badges (24h)' as badges_recentes,
    NOW()::text as verificado_em;

-- ============================================================================
-- 🎯 INSTRUÇÕES DE USO
-- ============================================================================

/*
🔍 VERIFICAÇÃO COMPLETA DO SISTEMA:

📋 O QUE ESTE ARQUIVO MOSTRA:
✅ Todas as funções customizadas (por categoria)
✅ Todos os triggers ativos (por tabela)
✅ Estatísticas de notificações, pontos e badges
✅ Verificações de integridade (duplicatas, inconsistências)
✅ Estrutura das tabelas principais
✅ Testes de funcionamento
✅ Resumo final do sistema

🎯 COMO USAR:
1. Execute este arquivo completo no Supabase
2. Analise os resultados por seção
3. Identifique problemas ou inconsistências
4. Use como referência para debugging

📊 SEÇÕES PRINCIPAIS:
- FUNÇÕES CUSTOMIZADAS → Todas as funções criadas
- TRIGGERS ATIVOS → Todos os triggers funcionando
- ESTATÍSTICAS → Contadores e métricas
- VERIFICAÇÕES → Problemas e inconsistências
- ESTRUTURA → Campos das tabelas
- RESUMO FINAL → Status geral do sistema

✅ EXECUTE SEMPRE QUE QUISER VERIFICAR O ESTADO ATUAL!
*/

