-- ============================================================================
-- LEVELS - DADOS INICIAIS DO SISTEMA
-- ============================================================================
-- Sistema de progressão por níveis do HoloSpot
-- 10 levels com faixas de pontos bem definidas
-- ============================================================================

-- ============================================================================
-- SISTEMA DE PROGRESSÃO - 10 LEVELS
-- ============================================================================

-- Level 1: Novato (0-99 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(1, 'Novato', 0, '🌱', '#4CAF50', 'Acesso básico', 0, 99);

-- Level 2: Iniciante (100-299 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(2, 'Iniciante', 100, '🔍', '#2196F3', 'Badge personalizado', 100, 299);

-- Level 3: Ativo (300-599 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(3, 'Ativo', 300, '⚡', '#FF9800', 'Destaque no perfil', 300, 599);

-- Level 4: Engajado (600-999 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(4, 'Engajado', 600, '🤝', '#9C27B0', 'Acesso a estatísticas avançadas', 600, 999);

-- Level 5: Influente (1000-1499 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(5, 'Influente', 1000, '📢', '#F44336', 'Destaque especial nos posts', 1000, 1499);

-- Level 6: Expert (1500-2499 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(6, 'Expert', 1500, '🎯', '#795548', 'Acesso a funcionalidades beta', 1500, 2499);

-- Level 7: Mentor (2500-3999 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(7, 'Mentor', 2500, '🧭', '#607D8B', 'Moderação de conteúdo', 2500, 3999);

-- Level 8: Líder (4000-6999 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(8, 'Líder', 4000, '👑', '#E91E63', 'Criação de eventos', 4000, 6999);

-- Level 9: Lenda (7000-9999 pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(9, 'Lenda', 7000, '⭐', '#9C27B0', 'Hall da fama', 7000, 9999);

-- Level 10: Imortal (10000+ pontos)
INSERT INTO levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES 
(10, 'Imortal', 10000, '💎', '#FFD700', 'Status permanente de destaque', 10000, 999999);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE levels IS 'Sistema de níveis de progressão do HoloSpot baseado em pontuação';

-- Comentários por campo
COMMENT ON COLUMN levels.points_required IS 'Pontos mínimos necessários para alcançar este nível';
COMMENT ON COLUMN levels.min_points IS 'Limite inferior da faixa de pontos deste nível';
COMMENT ON COLUMN levels.max_points IS 'Limite superior da faixa de pontos deste nível';
COMMENT ON COLUMN levels.color IS 'Cor hexadecimal para representação visual do nível';
COMMENT ON COLUMN levels.icon IS 'Emoji representativo do nível';
COMMENT ON COLUMN levels.benefits IS 'Benefícios desbloqueados ao alcançar este nível';

-- ============================================================================
-- ANÁLISE DO SISTEMA DE LEVELS
-- ============================================================================
-- 
-- Progressão Equilibrada:
-- - Início acessível: 0-99 pontos (Novato)
-- - Crescimento gradual: 100-299 (Iniciante), 300-599 (Ativo)
-- - Engajamento sério: 600-999 (Engajado), 1000-1499 (Influente)
-- - Elite do sistema: 1500+ pontos
-- 
-- Faixas de Pontos:
-- - Níveis 1-3: Faixas pequenas (100-300 pontos)
-- - Níveis 4-6: Faixas médias (400-1000 pontos)
-- - Níveis 7-10: Faixas grandes (1500-3000+ pontos)
-- 
-- Cores por Categoria:
-- - Verde (#4CAF50): Iniciante
-- - Azul (#2196F3): Aprendendo
-- - Laranja (#FF9800): Ativo
-- - Roxo (#9C27B0): Engajado
-- - Vermelho (#F44336): Influente
-- - Marrom (#795548): Expert
-- - Cinza (#607D8B): Mentor
-- - Rosa (#E91E63): Líder
-- - Roxo (#9C27B0): Lenda
-- - Dourado (#FFD700): Imortal
-- 
-- Benefícios Progressivos:
-- 1. Acesso básico
-- 2. Badge personalizado
-- 3. Destaque no perfil
-- 4. Estatísticas avançadas
-- 5. Destaque especial nos posts
-- 6. Funcionalidades beta
-- 7. Moderação de conteúdo
-- 8. Criação de eventos
-- 9. Hall da fama
-- 10. Status permanente
-- 
-- Tempo Estimado para Progressão:
-- - Novato → Iniciante: 1-2 semanas (usuário ativo)
-- - Iniciante → Ativo: 1-2 meses
-- - Ativo → Engajado: 2-3 meses
-- - Engajado → Influente: 3-6 meses
-- - Influente+: 6+ meses (usuários dedicados)
-- 
-- Distribuição Esperada:
-- - 60% dos usuários: Novato-Ativo (0-599 pontos)
-- - 30% dos usuários: Engajado-Influente (600-1499 pontos)
-- - 10% dos usuários: Expert+ (1500+ pontos)
-- 
-- ============================================================================

