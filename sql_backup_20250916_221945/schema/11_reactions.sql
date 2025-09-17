-- ============================================================================
-- REACTIONS TABLE - Sistema de Reações
-- ============================================================================
-- Tabela que armazena todas as reações dos usuários em posts
-- Sistema de engajamento emocional do HoloSpot
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.reactions (
    -- Identificador único da reação
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Referência ao post que recebeu a reação
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    
    -- Referência ao usuário que deu a reação
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Tipo da reação (obrigatório)
    type TEXT NOT NULL,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- CONSTRAINTS DA TABELA REACTIONS
-- ============================================================================

-- Constraint única para evitar reações duplicadas do mesmo usuário no mesmo post
ALTER TABLE public.reactions 
ADD CONSTRAINT unique_user_post_reaction 
UNIQUE (user_id, post_id);

-- ============================================================================
-- ÍNDICES DA TABELA REACTIONS
-- ============================================================================

-- Índice para busca por post (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_reactions_post_id 
ON public.reactions (post_id);

-- Índice para busca por usuário
CREATE INDEX IF NOT EXISTS idx_reactions_user_id 
ON public.reactions (user_id);

-- Índice para busca por tipo de reação
CREATE INDEX IF NOT EXISTS idx_reactions_type 
ON public.reactions (type);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_reactions_created_at 
ON public.reactions (created_at DESC);

-- Índice composto para busca eficiente por post e tipo
CREATE INDEX IF NOT EXISTS idx_reactions_post_type 
ON public.reactions (post_id, type);

-- Índice composto para busca por usuário e data
CREATE INDEX IF NOT EXISTS idx_reactions_user_created 
ON public.reactions (user_id, created_at DESC);

-- ============================================================================
-- TRIGGERS DA TABELA REACTIONS
-- ============================================================================

-- Trigger para verificação automática de badges após reação
CREATE TRIGGER auto_badge_check_bonus_reactions 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger para operações seguras de inserção (pontos)
CREATE TRIGGER reaction_insert_secure_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_insert_secure();

-- Trigger para operações seguras de deleção (pontos)
CREATE TRIGGER reaction_delete_secure_trigger 
    AFTER DELETE ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_delete_secure();

-- Trigger para pontos simplificados
CREATE TRIGGER reaction_points_simple_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_points_simple();

-- Trigger para notificação simples
CREATE TRIGGER reaction_simple_notification_trigger 
    AFTER INSERT ON public.reactions 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_reaction_simple();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.reactions IS 
'Tabela que armazena todas as reações dos usuários em posts.
Sistema de engajamento emocional do HoloSpot.';

COMMENT ON COLUMN public.reactions.id IS 'Identificador único da reação (UUID)';
COMMENT ON COLUMN public.reactions.post_id IS 'Referência ao post que recebeu a reação';
COMMENT ON COLUMN public.reactions.user_id IS 'Referência ao usuário que deu a reação';
COMMENT ON COLUMN public.reactions.type IS 'Tipo da reação (touched, inspired, grateful, etc.)';
COMMENT ON COLUMN public.reactions.created_at IS 'Timestamp de quando a reação foi criada';

-- ============================================================================
-- NOTAS SOBRE A TABELA REACTIONS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 5 campos simples e diretos
-- - UUID como chave primária com gen_random_uuid()
-- - Foreign keys para posts e profiles
-- - Tipo obrigatório (TEXT)
-- - Timestamp automático de criação
-- 
-- Relacionamentos:
-- - reactions.post_id → posts.id (CASCADE DELETE)
-- - reactions.user_id → profiles.id (CASCADE DELETE)
-- 
-- Tipos de Reação Comuns:
-- - touched: Emocionado/tocado (❤️)
-- - inspired: Inspirado (✨)
-- - grateful: Grato (🙏)
-- - proud: Orgulhoso (👏)
-- - amazed: Impressionado (😮)
-- 
-- Sistema de Pontuação:
-- - Quem dá reação: +3 pontos
-- - Autor do post: +2 pontos (se diferente)
-- - Registrado em points_history
-- 
-- Sistema de Notificações:
-- - Notifica autor do post quando recebe reação
-- - Inclui emoji específico por tipo
-- - Mensagens padronizadas
-- 
-- Triggers Ativos (5 total):
-- 1. auto_badge_check_bonus_reactions - Verificação de badges
-- 2. reaction_insert_secure_trigger - Pontos na inserção (seguro)
-- 3. reaction_delete_secure_trigger - Pontos na deleção (seguro)
-- 4. reaction_points_simple_trigger - Pontos simplificados
-- 5. reaction_simple_notification_trigger - Notificação simples
-- 
-- Funcionalidades:
-- - Reações emocionais em posts
-- - Sistema de engajamento
-- - Pontuação por interação
-- - Notificações automáticas
-- - Prevenção de duplicatas
-- 
-- Validações:
-- - Tipo obrigatório
-- - Uma reação por usuário por post
-- - Referências válidas (FK)
-- - Prevenção de auto-reação (lógica)
-- 
-- Performance:
-- - Índices otimizados para consultas comuns
-- - Busca eficiente por post e tipo
-- - Busca por usuário e data
-- - Constraint de unicidade
-- 
-- Integridade:
-- - Foreign keys garantem referências válidas
-- - Constraint única previne duplicatas
-- - Deleção em cascata mantém consistência
-- - Triggers garantem pontuação correta
-- 
-- Análise e Métricas:
-- - Contagem de reações por post
-- - Tipos de reação mais populares
-- - Engajamento por usuário
-- - Análise temporal de reações
-- 
-- Manutenção:
-- - Tabela de crescimento contínuo
-- - Monitoramento de performance
-- - Limpeza de dados órfãos
-- - Backup regular
-- 
-- ============================================================================

