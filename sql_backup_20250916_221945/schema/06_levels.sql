-- ============================================================================
-- LEVELS TABLE - Sistema de Níveis
-- ============================================================================
-- Tabela que define os níveis de progressão dos usuários
-- Sistema de gamificação baseado em pontos acumulados
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.levels (
    -- Identificador único do nível (INTEGER, não UUID)
    id INTEGER PRIMARY KEY,
    
    -- Nome do nível
    name VARCHAR(50) NOT NULL,
    
    -- Pontos necessários para atingir este nível
    points_required INTEGER NOT NULL,
    
    -- Ícone/emoji do nível
    icon VARCHAR(10) NOT NULL,
    
    -- Cor hexadecimal do nível (#RRGGBB)
    color VARCHAR(7) NOT NULL,
    
    -- Benefícios/descrição do nível
    benefits TEXT,
    
    -- Pontos mínimos do range deste nível
    min_points INTEGER,
    
    -- Pontos máximos do range deste nível
    max_points INTEGER
);

-- ============================================================================
-- ÍNDICES DA TABELA LEVELS
-- ============================================================================

-- Índice para busca por pontos necessários (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_levels_points_required 
ON public.levels (points_required);

-- Índice para busca por range de pontos
CREATE INDEX IF NOT EXISTS idx_levels_min_max_points 
ON public.levels (min_points, max_points);

-- Índice para ordenação por pontos
CREATE INDEX IF NOT EXISTS idx_levels_points_order 
ON public.levels (points_required ASC);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.levels IS 
'Tabela que define os níveis de progressão dos usuários.
Sistema de gamificação baseado em pontos acumulados.';

COMMENT ON COLUMN public.levels.id IS 'Identificador único do nível (INTEGER sequencial)';
COMMENT ON COLUMN public.levels.name IS 'Nome do nível exibido aos usuários';
COMMENT ON COLUMN public.levels.points_required IS 'Pontos necessários para atingir este nível';
COMMENT ON COLUMN public.levels.icon IS 'Ícone ou emoji representativo do nível';
COMMENT ON COLUMN public.levels.color IS 'Cor hexadecimal do nível para exibição (#RRGGBB)';
COMMENT ON COLUMN public.levels.benefits IS 'Descrição dos benefícios ou características do nível';
COMMENT ON COLUMN public.levels.min_points IS 'Pontos mínimos do range deste nível';
COMMENT ON COLUMN public.levels.max_points IS 'Pontos máximos do range deste nível';

-- ============================================================================
-- DADOS DE EXEMPLO E CONFIGURAÇÃO
-- ============================================================================

-- Exemplos de níveis do sistema (inserir após criação da tabela):
/*
INSERT INTO public.levels (id, name, points_required, icon, color, benefits, min_points, max_points) VALUES
(1, 'Iniciante', 0, '🌱', '#4CAF50', 'Bem-vindo ao HoloSpot! Comece a destacar pessoas e ganhar pontos.', 0, 99),
(2, 'Explorador', 100, '🔍', '#2196F3', 'Você está explorando o HoloSpot! Continue interagindo.', 100, 299),
(3, 'Colaborador', 300, '🤝', '#FF9800', 'Você é um colaborador ativo! Seus holofotes fazem a diferença.', 300, 699),
(4, 'Influenciador', 700, '⭐', '#9C27B0', 'Você é um influenciador! Suas ações inspiram outros.', 700, 1499),
(5, 'Lenda', 1500, '👑', '#F44336', 'Você é uma lenda do HoloSpot! Parabéns pela dedicação.', 1500, 999999);
*/

-- ============================================================================
-- NOTAS SOBRE A TABELA LEVELS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 8 campos com tipos específicos
-- - INTEGER como chave primária (não UUID)
-- - Campos obrigatórios: id, name, points_required, icon, color
-- - Campos opcionais: benefits, min_points, max_points
-- - Sem timestamps (tabela de configuração)
-- 
-- Características Especiais:
-- - Única tabela com INTEGER como PK (além de debug_feedback_test)
-- - Sem gen_random_uuid() ou timestamps
-- - Cor em formato hexadecimal (#RRGGBB)
-- - Sistema de ranges com min/max points
-- 
-- Sistema de Progressão:
-- - Baseado em pontos acumulados
-- - Níveis crescentes com thresholds
-- - Ranges definidos por min_points e max_points
-- - Benefícios específicos por nível
-- 
-- Integração com Sistema:
-- - Usado para determinar nível atual do usuário
-- - Exibição em perfis e interfaces
-- - Cores para diferenciação visual
-- - Ícones para representação gráfica
-- 
-- Funcionalidades:
-- - Progressão gamificada
-- - Motivação por conquistas
-- - Status social no sistema
-- - Diferenciação visual
-- 
-- Consultas Comuns:
-- - Buscar nível por pontos do usuário
-- - Listar todos os níveis ordenados
-- - Verificar próximo nível a atingir
-- - Calcular progresso atual
-- 
-- Validações Sugeridas:
-- - points_required deve ser crescente
-- - min_points <= max_points
-- - Cores em formato hexadecimal válido
-- - Ranges não devem se sobrepor
-- 
-- Manutenção:
-- - Tabela de configuração (poucos registros)
-- - Mudanças raras após definição inicial
-- - Backup importante para preservar configuração
-- - Testes necessários ao alterar ranges
-- 
-- ============================================================================

