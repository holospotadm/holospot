-- ============================================================================
-- DADOS INICIAIS - BADGES
-- ============================================================================

-- Badges básicos do sistema
INSERT INTO badges (id, name, description, icon, color, criteria, points_bonus) VALUES
(1, 'Primeiro Post', 'Criou seu primeiro post', '📝', '#3B82F6', 'first_post', 10),
(2, 'Primeiro Comentário', 'Fez seu primeiro comentário', '💬', '#10B981', 'first_comment', 5),
(3, 'Primeira Reação', 'Deu sua primeira reação', '👍', '#F59E0B', 'first_reaction', 5),
(4, 'Engajado', 'Recebeu 10 reações', '🔥', '#EF4444', 'reactions_received_10', 25),
(5, 'Popular', 'Recebeu 50 reações', '⭐', '#8B5CF6', 'reactions_received_50', 100);

