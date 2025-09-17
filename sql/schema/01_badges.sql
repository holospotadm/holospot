-- ============================================================================
-- BADGES TABLE - Sistema de Badges/Emblemas
-- ============================================================================
-- Tabela que define todos os badges disponíveis no sistema de gamificação
-- Contém critérios, raridades e configurações dos emblemas
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.badges (
    -- Identificador único do badge
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Nome do badge (máximo 100 caracteres)
    name VARCHAR(100) NOT NULL,
    
    -- Descrição detalhada do badge
    description TEXT NOT NULL,
    
    -- Ícone/emoji do badge (máximo 10 caracteres)
    icon VARCHAR(10) NOT NULL,
    
    -- Categoria do badge (máximo 50 caracteres)
    category VARCHAR(50) NOT NULL,
    
    -- Pontos necessários para conquistar o badge (opcional)
    points_required INTEGER DEFAULT 0,
    
    -- Tipo de condição para conquistar o badge
    condition_type VARCHAR(50) NOT NULL,
    
    -- Valor da condição (quantidade, threshold, etc.)
    condition_value INTEGER NOT NULL,
    
    -- Raridade do badge (common, rare, epic, legendary)
    rarity VARCHAR(20) DEFAULT 'common',
    
    -- Se o badge está ativo no sistema
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Timestamp de última atualização
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ÍNDICES DA TABELA BADGES
-- ============================================================================

-- Índice para busca por categoria
CREATE INDEX IF NOT EXISTS idx_badges_category 
ON public.badges (category);

-- Índice para busca por raridade
CREATE INDEX IF NOT EXISTS idx_badges_rarity 
ON public.badges (rarity);

-- Índice para badges ativos
CREATE INDEX IF NOT EXISTS idx_badges_is_active 
ON public.badges (is_active);

-- Índice para busca por tipo de condição
CREATE INDEX IF NOT EXISTS idx_badges_condition_type 
ON public.badges (condition_type);

-- Índice composto para busca eficiente por categoria e raridade
CREATE INDEX IF NOT EXISTS idx_badges_category_rarity 
ON public.badges (category, rarity);

-- ============================================================================
-- TRIGGERS DA TABELA BADGES
-- ============================================================================

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_badges_updated_at 
    BEFORE UPDATE ON public.badges 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.badges IS 
'Tabela que define todos os badges/emblemas disponíveis no sistema de gamificação.
Contém critérios de conquista, raridades e configurações dos emblemas.';

COMMENT ON COLUMN public.badges.id IS 'Identificador único do badge (UUID)';
COMMENT ON COLUMN public.badges.name IS 'Nome do badge exibido aos usuários';
COMMENT ON COLUMN public.badges.description IS 'Descrição detalhada do que o badge representa';
COMMENT ON COLUMN public.badges.icon IS 'Ícone ou emoji representativo do badge';
COMMENT ON COLUMN public.badges.category IS 'Categoria do badge (holofote, coração, engajamento, etc.)';
COMMENT ON COLUMN public.badges.points_required IS 'Pontos mínimos necessários para conquistar o badge';
COMMENT ON COLUMN public.badges.condition_type IS 'Tipo de condição (posts_count, reactions_received, etc.)';
COMMENT ON COLUMN public.badges.condition_value IS 'Valor threshold da condição para conquistar o badge';
COMMENT ON COLUMN public.badges.rarity IS 'Raridade do badge (common, rare, epic, legendary)';
COMMENT ON COLUMN public.badges.is_active IS 'Se o badge está ativo e pode ser conquistado';
COMMENT ON COLUMN public.badges.created_at IS 'Timestamp de criação do badge';
COMMENT ON COLUMN public.badges.updated_at IS 'Timestamp de última atualização do badge';

-- ============================================================================
-- DADOS DE EXEMPLO E CONFIGURAÇÃO
-- ============================================================================

-- Exemplos de badges do sistema (inserir após criação da tabela):
/*
INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity) VALUES
('Primeiro Holofote', 'Criou seu primeiro post destacando alguém', '✨', 'holofote', 'posts_count', 1, 'common'),
('Coração Generoso', 'Deu 10 reações em posts', '❤️', 'coração', 'reactions_given', 10, 'common'),
('Engajador', 'Recebeu 50 reações em seus posts', '🔥', 'engajamento', 'reactions_received', 50, 'rare'),
('Lenda do HoloSpot', 'Atingiu 10.000 pontos totais', '👑', 'lenda', 'total_points', 10000, 'legendary');
*/

-- ============================================================================
-- NOTAS SOBRE A TABELA BADGES
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 12 campos com tipos específicos
-- - UUID como chave primária com uuid_generate_v4()
-- - Campos obrigatórios: name, description, icon, category, condition_type, condition_value
-- - Campos opcionais com defaults: points_required, rarity, is_active
-- - Timestamps automáticos: created_at, updated_at
-- 
-- Sistema de Raridade:
-- - common: Badges básicos, fáceis de conquistar
-- - rare: Badges que requerem mais esforço
-- - epic: Badges para conquistas significativas
-- - legendary: Badges para conquistas excepcionais
-- 
-- Tipos de Condição Comuns:
-- - posts_count: Número de posts criados
-- - reactions_given: Número de reações dadas
-- - reactions_received: Número de reações recebidas
-- - comments_given: Número de comentários feitos
-- - feedbacks_given: Número de feedbacks dados
-- - total_points: Total de pontos acumulados
-- - streak_days: Dias consecutivos de atividade
-- 
-- Categorias Principais:
-- - holofote: Badges relacionados a criar posts
-- - coração: Badges relacionados a dar reações
-- - engajamento: Badges relacionados a receber interações
-- - comunidade: Badges relacionados a interações sociais
-- - lenda: Badges especiais e raros
-- 
-- Integração com Sistema:
-- - Verificação automática via triggers de gamificação
-- - Concessão automática baseada em critérios
-- - Notificações automáticas quando conquistados
-- - Exibição em perfis de usuários
-- 
-- ============================================================================

