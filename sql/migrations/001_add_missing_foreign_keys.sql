-- ============================================================================
-- MIGRATION 001: Adicionar Foreign Keys Faltantes
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Adicionar integridade referencial básica que estava faltando
-- Tabelas afetadas: user_points, feedbacks
-- ============================================================================

-- Verificar dados antes de aplicar FKs
-- ============================================================================

-- 1. Verificar se todos os level_id em user_points existem em levels
DO $$
DECLARE
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO invalid_count
    FROM user_points up
    LEFT JOIN levels l ON up.level_id = l.id
    WHERE l.id IS NULL;
    
    IF invalid_count > 0 THEN
        RAISE NOTICE 'ATENÇÃO: % registros em user_points com level_id inválido', invalid_count;
        RAISE NOTICE 'Execute: SELECT DISTINCT level_id FROM user_points WHERE level_id NOT IN (SELECT id FROM levels);';
    ELSE
        RAISE NOTICE 'OK: Todos os level_id são válidos';
    END IF;
END $$;

-- 2. Verificar dados órfãos em feedbacks
DO $$
DECLARE
    orphan_posts INTEGER;
    orphan_authors INTEGER;
    orphan_mentioned INTEGER;
BEGIN
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
    
    RAISE NOTICE 'Feedbacks órfãos - Posts: %, Authors: %, Mentioned: %', 
                 orphan_posts, orphan_authors, orphan_mentioned;
END $$;

-- Adicionar Foreign Keys
-- ============================================================================

-- 1. user_points.level_id → levels.id
ALTER TABLE user_points 
ADD CONSTRAINT fk_user_points_level 
FOREIGN KEY (level_id) REFERENCES levels(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

COMMENT ON CONSTRAINT fk_user_points_level ON user_points IS 
'Garante que level_id sempre referencia um nível válido';

-- 2. feedbacks.post_id → posts.id
ALTER TABLE feedbacks 
ADD CONSTRAINT fk_feedbacks_post 
FOREIGN KEY (post_id) REFERENCES posts(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

COMMENT ON CONSTRAINT fk_feedbacks_post ON feedbacks IS 
'Garante que post_id sempre referencia um post válido';

-- 3. feedbacks.author_id → profiles.id
ALTER TABLE feedbacks 
ADD CONSTRAINT fk_feedbacks_author 
FOREIGN KEY (author_id) REFERENCES profiles(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

COMMENT ON CONSTRAINT fk_feedbacks_author ON feedbacks IS 
'Garante que author_id sempre referencia um usuário válido';

-- 4. feedbacks.mentioned_user_id → profiles.id
ALTER TABLE feedbacks 
ADD CONSTRAINT fk_feedbacks_mentioned_user 
FOREIGN KEY (mentioned_user_id) REFERENCES profiles(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

COMMENT ON CONSTRAINT fk_feedbacks_mentioned_user ON feedbacks IS 
'Garante que mentioned_user_id sempre referencia um usuário válido';

-- Verificação final
-- ============================================================================

-- Listar todas as FKs adicionadas
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
    AND tc.constraint_name IN (
        'fk_user_points_level',
        'fk_feedbacks_post', 
        'fk_feedbacks_author',
        'fk_feedbacks_mentioned_user'
    )
ORDER BY tc.table_name, tc.constraint_name;

-- ============================================================================
-- ROLLBACK (se necessário)
-- ============================================================================
/*
-- Para reverter as mudanças:
ALTER TABLE user_points DROP CONSTRAINT IF EXISTS fk_user_points_level;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_post;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_author;
ALTER TABLE feedbacks DROP CONSTRAINT IF EXISTS fk_feedbacks_mentioned_user;
*/

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ MIGRATION 001 CONCLUÍDA: Foreign Keys adicionadas com sucesso!';
    RAISE NOTICE '📊 Total de FKs adicionadas: 4';
    RAISE NOTICE '🔗 Tabelas afetadas: user_points, feedbacks';
    RAISE NOTICE '🛡️ Integridade referencial melhorada significativamente';
END $$;

