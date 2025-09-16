-- ============================================================================
-- BADGES - DADOS INICIAIS DO SISTEMA
-- ============================================================================
-- Dados essenciais para inicialização do sistema de gamificação HoloSpot
-- 20 badges organizados por categoria e raridade
-- ============================================================================

-- ============================================================================
-- MILESTONE BADGES - Marcos Importantes (6 badges)
-- ============================================================================

-- Primeiros passos no HoloSpot
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('aa4b0862-0172-4049-a629-b1a6f80ee755', 'Primeiro Post', 'Criou seu primeiro post no HoloSpot', '📝', 'milestone', 0, 'posts_count', 1, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('c2ef5cb4-c9fc-4466-8a58-d717f999ac69', 'Primeira Reação', 'Deu sua primeira reação em um post', '👍', 'milestone', 0, 'reactions_given', 1, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('ff9c1c68-b37e-4bc0-9d19-915e90942762', 'Primeiro Holofote', 'Destacou alguém pela primeira vez', '🌟', 'milestone', 0, 'holofotes_given', 1, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('94c2af9c-d103-4284-b7ac-471d6f3c82fc', 'Primeira Interação', 'Recebeu sua primeira interação', '🎉', 'milestone', 0, 'interactions_received', 1, 'common', true);

-- Progressão de posts
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('b8f7c2a1-4d5e-6f7a-8b9c-0d1e2f3a4b5c', 'Ativo', 'Criou 10 posts', '📖', 'milestone', 200, 'posts_count', 10, 'uncommon', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('f5d12e8a-6371-4947-b58d-00ce296749c1', 'Prolífico', 'Criou 50 posts', '📚', 'milestone', 800, 'posts_count', 50, 'rare', true);

-- ============================================================================
-- ENGAGEMENT BADGES - Engajamento e Atividade (8 badges)
-- ============================================================================

-- Reações
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('1ba8890a-5c4e-47c6-b9a1-18ac9bf7054e', 'Engajador', 'Deu 50 reações em posts', '💪', 'engagement', 100, 'reactions_given', 50, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('cc633b75-31cd-451b-8578-c18870a924a1', 'Super Engajador', 'Deu 200 reações em posts', '🔥', 'engagement', 300, 'reactions_given', 200, 'rare', true);

-- Comentários
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('d9eadb57-d1e1-4d22-a33f-5b51e5c2ea54', 'Comentarista', 'Escreveu 25 comentários', '💬', 'engagement', 150, 'comments_written', 25, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('f8e8d243-f414-483a-aec0-c85499091295', 'Conversador', 'Escreveu 100 comentários', '🗣️', 'engagement', 500, 'comments_written', 100, 'rare', true);

-- Streaks
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('fe9a9566-c193-4d50-99b9-0351cdfc6287', 'Consistente', 'Manteve streak de 7 dias', '📅', 'engagement', 100, 'streak_days', 7, 'common', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('6dafc7a0-7c47-4fd0-89b9-2025760b3dac', 'Dedicado', 'Manteve streak de 30 dias', '🔥', 'engagement', 500, 'streak_days', 30, 'rare', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('a977888c-8748-487c-ae83-b7304574ccdb', 'Incansável', 'Manteve streak de 100 dias', '💎', 'engagement', 1500, 'streak_days', 100, 'legendary', true);

-- Feedbacks
INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('e1f2a3b4-c5d6-7e8f-9a0b-1c2d3e4f5a6b', 'Feedback Master', 'Deu 50 feedbacks', '📝', 'engagement', 400, 'feedbacks_given', 50, 'uncommon', true);

-- ============================================================================
-- SOCIAL BADGES - Interação Social (3 badges)
-- ============================================================================

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('700ed2f4-b70f-4eb2-a893-8928b6652389', 'Mentor', 'Destacou 25 pessoas diferentes', '🧭', 'social', 600, 'unique_people_highlighted', 25, 'rare', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('1aef1c37-7405-4a3a-be84-0b037e3e0342', 'Querido', 'Recebeu 500 reações', '💖', 'social', 800, 'reactions_received', 500, 'rare', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Popular', 'Recebeu 100 comentários', '⭐', 'social', 400, 'comments_received', 100, 'uncommon', true);

-- ============================================================================
-- SPECIAL BADGES - Conquistas Especiais (3 badges)
-- ============================================================================

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('31412892-ab57-4f59-a1bb-2e8316625892', 'Pioneiro', 'Um dos primeiros usuários do HoloSpot', '🚀', 'special', 0, 'early_adopter', 1, 'legendary', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('904964ab-1f91-406a-bc49-4e629b2e2492', 'Influenciador', 'Seus posts receberam 1000 interações', '📈', 'special', 2000, 'total_post_interactions', 1000, 'legendary', true);

INSERT INTO badges (id, name, description, icon, category, points_required, condition_type, condition_value, rarity, is_active) VALUES 
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'Embaixador', 'Trouxe 10 novos usuários', '🤝', 'special', 1000, 'referrals_count', 10, 'epic', true);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE badges IS 'Sistema de badges para gamificação do HoloSpot';

-- Comentários por categoria
COMMENT ON COLUMN badges.category IS 'Categorias: milestone (marcos), engagement (engajamento), social (interação), special (especiais)';
COMMENT ON COLUMN badges.rarity IS 'Raridades: common (comum), uncommon (incomum), rare (raro), epic (épico), legendary (lendário)';
COMMENT ON COLUMN badges.condition_type IS 'Tipo de condição para desbloqueio do badge';
COMMENT ON COLUMN badges.condition_value IS 'Valor necessário para satisfazer a condição';
COMMENT ON COLUMN badges.points_required IS 'Pontos mínimos necessários para desbloquear (além da condição)';

-- ============================================================================
-- ESTATÍSTICAS DOS BADGES
-- ============================================================================
-- 
-- Total: 20 badges
-- 
-- Por Categoria:
-- - milestone: 6 badges (marcos importantes)
-- - engagement: 8 badges (atividade e engajamento)  
-- - social: 3 badges (interação social)
-- - special: 3 badges (conquistas especiais)
-- 
-- Por Raridade:
-- - common: 8 badges (40%)
-- - uncommon: 2 badges (10%)
-- - rare: 6 badges (30%)
-- - epic: 2 badges (10%)
-- - legendary: 2 badges (10%)
-- 
-- Faixa de Pontos:
-- - Mínimo: 0 pontos (marcos iniciais)
-- - Máximo: 2.000 pontos (influenciador)
-- - Média: ~500 pontos
-- 
-- Progressão Sugerida:
-- 1. Marcos iniciais (0 pontos)
-- 2. Engajamento básico (100-200 pontos)
-- 3. Atividade regular (300-500 pontos)
-- 4. Conquistas avançadas (600-1000 pontos)
-- 5. Elite do sistema (1500-2000 pontos)
-- 
-- ============================================================================

