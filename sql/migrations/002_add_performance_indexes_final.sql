-- ============================================================================
-- MIGRATION 002: Adicionar Índices de Performance (VERSÃO FINAL)
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Melhorar performance das consultas mais frequentes
-- Baseado na estrutura REAL das tabelas (sem deleted_at)
-- ============================================================================

-- Análise antes da criação
-- ============================================================================

-- Verificar tamanho das tabelas principais
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE schemaname = 'public' 
    AND tablename IN ('posts', 'comments', 'reactions', 'notifications')
    AND attname IN ('created_at', 'user_id', 'post_id', 'mentioned_user_id', 'is_read')
ORDER BY tablename, attname;

-- Criar índices de performance
-- ============================================================================

-- 1. Feed principal - Posts ordenados por data
CREATE INDEX idx_posts_active_feed 
ON posts(created_at DESC);

-- 2. Posts por usuário - Perfil do usuário
CREATE INDEX idx_posts_user_active 
ON posts(user_id, created_at DESC);

-- 3. Holofotes recebidos - Sistema core
CREATE INDEX idx_posts_mentions_active 
ON posts(mentioned_user_id, created_at DESC) 
WHERE mentioned_user_id IS NOT NULL;

-- 4. Comentários por post - Ordenados cronologicamente
CREATE INDEX idx_comments_by_post_ordered 
ON comments(post_id, created_at ASC);

-- Adicionar comentários aos índices
-- ============================================================================

COMMENT ON INDEX idx_posts_active_feed IS 
'Otimiza carregamento do feed principal - posts ordenados por data';

COMMENT ON INDEX idx_posts_user_active IS 
'Otimiza visualização de posts no perfil do usuário';

COMMENT ON INDEX idx_posts_mentions_active IS 
'Otimiza sistema de holofotes - posts que mencionam usuários';

COMMENT ON INDEX idx_comments_by_post_ordered IS 
'Otimiza carregamento de comentários por post em ordem cronológica';

-- Verificação dos índices criados
-- ============================================================================

-- Listar novos índices
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND indexname IN (
        'idx_posts_active_feed',
        'idx_posts_user_active', 
        'idx_posts_mentions_active',
        'idx_comments_by_post_ordered'
    )
ORDER BY tablename, indexname;

-- Análise de uso esperado
-- ============================================================================

DO $$
DECLARE
    posts_count INTEGER;
    comments_count INTEGER;
    posts_with_mentions INTEGER;
BEGIN
    -- Contar registros
    SELECT COUNT(*) INTO posts_count FROM posts;
    SELECT COUNT(*) INTO comments_count FROM comments;
    SELECT COUNT(*) INTO posts_with_mentions FROM posts WHERE mentioned_user_id IS NOT NULL;
    
    RAISE NOTICE '📊 ESTATÍSTICAS DAS TABELAS:';
    RAISE NOTICE '   Posts total: %', posts_count;
    RAISE NOTICE '   Posts com menções: %', posts_with_mentions;
    RAISE NOTICE '   Comentários: %', comments_count;
    RAISE NOTICE '';
    RAISE NOTICE '🎯 ÍNDICES OTIMIZADOS PARA:';
    RAISE NOTICE '   ✅ Feed principal (posts por data)';
    RAISE NOTICE '   ✅ Perfil do usuário (posts por user_id)';
    RAISE NOTICE '   ✅ Sistema de holofotes (mentioned_user_id)';
    RAISE NOTICE '   ✅ Comentários por post (ordenação cronológica)';
END $$;

-- Queries de exemplo que serão otimizadas
-- ============================================================================

-- EXEMPLO 1: Feed principal
/*
SELECT id, content, user_id, mentioned_user_id, created_at
FROM posts 
ORDER BY created_at DESC 
LIMIT 20;
-- Usará: idx_posts_active_feed
*/

-- EXEMPLO 2: Posts do usuário
/*
SELECT id, content, mentioned_user_id, created_at
FROM posts 
WHERE user_id = 'user-uuid-here' 
ORDER BY created_at DESC 
LIMIT 10;
-- Usará: idx_posts_user_active
*/

-- EXEMPLO 3: Holofotes recebidos
/*
SELECT id, content, user_id, created_at
FROM posts 
WHERE mentioned_user_id = 'user-uuid-here' 
ORDER BY created_at DESC 
LIMIT 10;
-- Usará: idx_posts_mentions_active
*/

-- EXEMPLO 4: Comentários do post
/*
SELECT id, user_id, content, created_at
FROM comments 
WHERE post_id = 'post-uuid-here' 
ORDER BY created_at ASC;
-- Usará: idx_comments_by_post_ordered
*/

-- ============================================================================
-- MONITORAMENTO
-- ============================================================================

-- Query para monitorar uso dos índices após implementação
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as "Vezes usado",
    idx_tup_read as "Tuplas lidas",
    idx_tup_fetch as "Tuplas buscadas"
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
    AND indexname IN (
        'idx_posts_active_feed',
        'idx_posts_user_active', 
        'idx_posts_mentions_active',
        'idx_comments_by_post_ordered'
    )
ORDER BY idx_scan DESC;

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 002 CONCLUÍDA: Índices de performance adicionados!';
    RAISE NOTICE '📊 Total de índices adicionados: 4';
    RAISE NOTICE '🚀 Funcionalidades otimizadas:';
    RAISE NOTICE '   • Feed principal (posts por data)';
    RAISE NOTICE '   • Perfil do usuário (posts por user_id)';
    RAISE NOTICE '   • Sistema de holofotes (mentioned_user_id)';
    RAISE NOTICE '   • Comentários por post (ordenação cronológica)';
    RAISE NOTICE '⚡ Performance significativamente melhorada!';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Baseado na estrutura REAL das tabelas (sem deleted_at)';
END $$;

