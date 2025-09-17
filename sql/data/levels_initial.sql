-- ============================================================================
-- DADOS INICIAIS - LEVELS
-- ============================================================================

-- Níveis do sistema de gamificação
INSERT INTO levels (id, name, min_points, color, benefits) VALUES
(1, 'Iniciante', 0, '#94A3B8', 'Acesso básico à plataforma'),
(2, 'Explorador', 100, '#3B82F6', 'Pode criar posts e comentários'),
(3, 'Colaborador', 300, '#10B981', 'Pode dar feedbacks e reações'),
(4, 'Especialista', 750, '#F59E0B', 'Acesso a recursos avançados'),
(5, 'Mentor', 1500, '#EF4444', 'Pode moderar conteúdo'),
(6, 'Líder', 3000, '#8B5CF6', 'Acesso completo à plataforma');

