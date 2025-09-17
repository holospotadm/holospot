-- ============================================================================
-- RELACIONAMENTOS E FOREIGN KEYS - HOLOSPOT
-- ============================================================================
-- Mapeamento de relacionamentos entre tabelas
-- ============================================================================

-- Para listar todas as foreign keys, execute:
-- SELECT
--     tc.table_name,
--     kcu.column_name,
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name,
--     tc.constraint_name
-- FROM information_schema.table_constraints AS tc 
-- JOIN information_schema.key_column_usage AS kcu
--     ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--     ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' 
-- AND tc.table_schema = 'public'
-- ORDER BY tc.table_name, kcu.column_name;


-- RELACIONAMENTOS PRINCIPAIS ESPERADOS:
-- ============================================================================

-- posts -> profiles (author_id)
-- comments -> profiles (author_id)
-- comments -> posts (post_id)
-- reactions -> profiles (user_id)
-- reactions -> posts (post_id)
-- feedbacks -> profiles (author_id, mentioned_user_id)
-- feedbacks -> posts (post_id)
-- follows -> profiles (follower_id, following_id)
-- user_points -> profiles (user_id)
-- user_points -> levels (level_id)
-- user_badges -> profiles (user_id)
-- user_badges -> badges (badge_id)
-- user_streaks -> profiles (user_id)
-- points_history -> profiles (user_id)
-- notifications -> profiles (user_id, from_user_id)

