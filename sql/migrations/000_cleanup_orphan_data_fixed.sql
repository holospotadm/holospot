-- ============================================================================
-- MIGRATION 000: Limpeza de Dados Órfãos (CORRIGIDO)
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Limpar dados órfãos antes de aplicar Foreign Keys
-- EXECUTAR ANTES da Migration 001
-- ============================================================================

-- Análise dos dados órfãos
-- ============================================================================

-- 1. Verificar dados órfãos em feedbacks
DO $$
DECLARE
    orphan_posts INTEGER;
    orphan_authors INTEGER;
    orphan_mentioned INTEGER;
    total_feedbacks INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_feedbacks FROM feedbacks;
    
    -- Posts órfãos
    SELECT COUNT(*) INTO orphan_posts
    FROM feedbacks f
    LEFT JOIN posts p ON f.post_id = p.id
    WHERE f.post_id IS NOT NULL AND p.id IS NULL;
    
    -- Authors órfãos
    SELECT COUNT(*) INTO orphan_authors
    FROM feedbacks f
    LEFT JOIN profiles pr ON f.author_id = pr.id
    WHERE f.author_id IS NOT NULL AND pr.id IS NULL;
    
    -- Mentioned users órfãos
    SELECT COUNT(*) INTO orphan_mentioned
    FROM feedbacks f
    LEFT JOIN profiles pr ON f.mentioned_user_id = pr.id
    WHERE f.mentioned_user_id IS NOT NULL AND pr.id IS NULL;
    
    RAISE NOTICE '📊 ANÁLISE DE DADOS ÓRFÃOS:';
    RAISE NOTICE '   Total feedbacks: %', total_feedbacks;
    RAISE NOTICE '   Posts órfãos: %', orphan_posts;
    RAISE NOTICE '   Authors órfãos: %', orphan_authors;
    RAISE NOTICE '   Mentioned órfãos: %', orphan_mentioned;
    RAISE NOTICE '';
END $$;

-- 2. Verificar user_points.level_id
DO $$
DECLARE
    invalid_levels INTEGER;
    total_user_points INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_user_points FROM user_points;
    
    SELECT COUNT(*) INTO invalid_levels
    FROM user_points up
    LEFT JOIN levels l ON up.level_id = l.id
    WHERE l.id IS NULL;
    
    RAISE NOTICE '📊 ANÁLISE USER_POINTS:';
    RAISE NOTICE '   Total user_points: %', total_user_points;
    RAISE NOTICE '   Levels inválidos: %', invalid_levels;
    RAISE NOTICE '';
END $$;

-- Mostrar dados órfãos específicos
-- ============================================================================

-- Authors órfãos
SELECT 'AUTHORS ÓRFÃOS EM FEEDBACKS:' as analise;
SELECT DISTINCT f.author_id, COUNT(*) as quantidade
FROM feedbacks f
LEFT JOIN profiles p ON f.author_id = p.id
WHERE f.author_id IS NOT NULL AND p.id IS NULL
GROUP BY f.author_id
ORDER BY quantidade DESC
LIMIT 10;

-- Posts órfãos
SELECT 'POSTS ÓRFÃOS EM FEEDBACKS:' as analise;
SELECT DISTINCT f.post_id, COUNT(*) as quantidade
FROM feedbacks f
LEFT JOIN posts p ON f.post_id = p.id
WHERE f.post_id IS NOT NULL AND p.id IS NULL
GROUP BY f.post_id
ORDER BY quantidade DESC
LIMIT 10;

-- Mentioned users órfãos
SELECT 'MENTIONED USERS ÓRFÃOS EM FEEDBACKS:' as analise;
SELECT DISTINCT f.mentioned_user_id, COUNT(*) as quantidade
FROM feedbacks f
LEFT JOIN profiles p ON f.mentioned_user_id = p.id
WHERE f.mentioned_user_id IS NOT NULL AND p.id IS NULL
GROUP BY f.mentioned_user_id
ORDER BY quantidade DESC
LIMIT 10;

-- Limpeza dos dados órfãos
-- ============================================================================

-- Backup dos dados que serão deletados
CREATE TEMP TABLE feedbacks_backup AS
SELECT * FROM feedbacks f
WHERE 
    -- Posts órfãos
    (f.post_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM posts p WHERE p.id = f.post_id))
    OR
    -- Authors órfãos  
    (f.author_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.author_id))
    OR
    -- Mentioned users órfãos
    (f.mentioned_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.mentioned_user_id));

-- Mostrar quantos serão deletados
DO $$
DECLARE
    backup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO backup_count FROM feedbacks_backup;
    RAISE NOTICE '💾 BACKUP CRIADO: % feedbacks órfãos salvos em feedbacks_backup', backup_count;
END $$;

-- Deletar feedbacks com posts órfãos
DELETE FROM feedbacks f
WHERE f.post_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM posts p WHERE p.id = f.post_id);

-- Deletar feedbacks com authors órfãos
DELETE FROM feedbacks f
WHERE f.author_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.author_id);

-- Deletar feedbacks com mentioned users órfãos
DELETE FROM feedbacks f
WHERE f.mentioned_user_id IS NOT NULL 
    AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.mentioned_user_id);

-- Corrigir user_points.level_id inválidos
-- ============================================================================

-- Backup dos dados que serão corrigidos
CREATE TEMP TABLE user_points_backup AS
SELECT * FROM user_points up
WHERE NOT EXISTS (SELECT 1 FROM levels l WHERE l.id = up.level_id);

-- Corrigir level_id inválidos para level 1 (assumindo que existe)
UPDATE user_points 
SET level_id = 1
WHERE NOT EXISTS (SELECT 1 FROM levels l WHERE l.id = user_points.level_id);

-- Verificação final
-- ============================================================================

DO $$
DECLARE
    remaining_orphans INTEGER;
    remaining_invalid_levels INTEGER;
    deleted_feedbacks INTEGER;
    corrected_user_points INTEGER;
BEGIN
    -- Contar dados corrigidos
    SELECT COUNT(*) INTO deleted_feedbacks FROM feedbacks_backup;
    SELECT COUNT(*) INTO corrected_user_points FROM user_points_backup;
    
    -- Verificar feedbacks órfãos restantes
    SELECT COUNT(*) INTO remaining_orphans
    FROM feedbacks f
    WHERE 
        (f.post_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM posts p WHERE p.id = f.post_id))
        OR
        (f.author_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.author_id))
        OR
        (f.mentioned_user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profiles p WHERE p.id = f.mentioned_user_id));
    
    -- Verificar levels inválidos restantes
    SELECT COUNT(*) INTO remaining_invalid_levels
    FROM user_points up
    WHERE NOT EXISTS (SELECT 1 FROM levels l WHERE l.id = up.level_id);
    
    RAISE NOTICE '✅ LIMPEZA CONCLUÍDA:';
    RAISE NOTICE '   Feedbacks deletados: %', deleted_feedbacks;
    RAISE NOTICE '   User_points corrigidos: %', corrected_user_points;
    RAISE NOTICE '   Feedbacks órfãos restantes: %', remaining_orphans;
    RAISE NOTICE '   Levels inválidos restantes: %', remaining_invalid_levels;
    RAISE NOTICE '';
    
    IF remaining_orphans = 0 AND remaining_invalid_levels = 0 THEN
        RAISE NOTICE '🎉 DADOS LIMPOS! Pronto para aplicar Foreign Keys!';
    ELSE
        RAISE NOTICE '⚠️  Ainda existem dados inconsistentes!';
    END IF;
END $$;

-- Estatísticas finais
-- ============================================================================

SELECT 
    'ESTATÍSTICAS FINAIS' as resultado,
    'feedbacks' as tabela,
    COUNT(*) as total_registros
FROM feedbacks
UNION ALL
SELECT 
    'ESTATÍSTICAS FINAIS' as resultado,
    'user_points' as tabela,
    COUNT(*) as total_registros
FROM user_points
ORDER BY tabela;

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 000 CONCLUÍDA: Dados órfãos limpos!';
    RAISE NOTICE '📊 Tabelas limpas: feedbacks, user_points';
    RAISE NOTICE '💾 Backups criados: feedbacks_backup, user_points_backup';
    RAISE NOTICE '🚀 Pronto para executar Migration 001 (Foreign Keys)!';
END $$;

