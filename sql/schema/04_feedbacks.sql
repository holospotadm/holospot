-- ============================================================================
-- FEEDBACKS TABLE - Sistema de Feedbacks
-- ============================================================================
-- Tabela que armazena feedbacks dados por usuários sobre posts
-- Sistema de reconhecimento e feedback construtivo
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.feedbacks (
    -- Identificador único do feedback (BIGINT, não UUID)
    id BIGINT PRIMARY KEY,
    
    -- Timestamp de criação (obrigatório)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Referência ao post (com default gen_random_uuid)
    post_id UUID DEFAULT gen_random_uuid(),
    
    -- Referência ao autor do feedback (com default gen_random_uuid)
    author_id UUID DEFAULT gen_random_uuid(),
    
    -- Texto do feedback
    feedback_text TEXT,
    
    -- Usuário mencionado no feedback
    mentioned_user_id UUID
);

-- ============================================================================
-- ÍNDICES DA TABELA FEEDBACKS
-- ============================================================================

-- Índice para busca por post
CREATE INDEX IF NOT EXISTS idx_feedbacks_post_id 
ON public.feedbacks (post_id);

-- Índice para busca por autor
CREATE INDEX IF NOT EXISTS idx_feedbacks_author_id 
ON public.feedbacks (author_id);

-- Índice para busca por usuário mencionado
CREATE INDEX IF NOT EXISTS idx_feedbacks_mentioned_user_id 
ON public.feedbacks (mentioned_user_id);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_feedbacks_created_at 
ON public.feedbacks (created_at DESC);

-- ============================================================================
-- TRIGGERS DA TABELA FEEDBACKS
-- ============================================================================

-- Trigger para verificação automática de badges após feedback
CREATE TRIGGER auto_badge_check_bonus_feedbacks 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger para operações seguras de inserção (pontos)
CREATE TRIGGER feedback_insert_secure_trigger 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_feedback_insert_secure();

-- Trigger para notificação correta
CREATE TRIGGER feedback_notification_correto_trigger 
    AFTER INSERT ON public.feedbacks 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_feedback_notification_correto();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.feedbacks IS 
'Tabela que armazena feedbacks dados por usuários sobre posts.
Sistema de reconhecimento e feedback construtivo do HoloSpot.';

COMMENT ON COLUMN public.feedbacks.id IS 'Identificador único do feedback (BIGINT)';
COMMENT ON COLUMN public.feedbacks.created_at IS 'Timestamp de criação do feedback (obrigatório)';
COMMENT ON COLUMN public.feedbacks.post_id IS 'Referência ao post que recebeu o feedback';
COMMENT ON COLUMN public.feedbacks.author_id IS 'Referência ao usuário que deu o feedback';
COMMENT ON COLUMN public.feedbacks.feedback_text IS 'Conteúdo textual do feedback';
COMMENT ON COLUMN public.feedbacks.mentioned_user_id IS 'Usuário mencionado/destacado no feedback';

-- ============================================================================
-- NOTAS SOBRE A TABELA FEEDBACKS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 6 campos com estrutura específica
-- - BIGINT como chave primária (não UUID como outras tabelas)
-- - created_at obrigatório (diferente de outras tabelas)
-- - post_id e author_id com defaults gen_random_uuid()
-- - Campos opcionais: feedback_text, mentioned_user_id
-- 
-- Peculiaridades Estruturais:
-- - ID é BIGINT em vez de UUID (única tabela assim)
-- - created_at é NOT NULL (outras tabelas permitem NULL)
-- - Defaults gen_random_uuid() em campos UUID
-- - Sem foreign keys explícitas (relacionamentos implícitos)
-- 
-- Sistema de Pontuação:
-- - Quem dá feedback: +8 pontos (maior valor)
-- - Quem recebe feedback: +5 pontos
-- - Registrado em points_history
-- 
-- Sistema de Notificações:
-- - Notifica usuário mencionado quando recebe feedback
-- - Sistema anti-spam com janela de 24 horas
-- - Mensagens padronizadas sem exclamações
-- 
-- Triggers Ativos (3 total):
-- 1. auto_badge_check_bonus_feedbacks - Verificação de badges
-- 2. feedback_insert_secure_trigger - Pontos na inserção
-- 3. feedback_notification_correto_trigger - Notificação
-- 
-- Funcionalidades:
-- - Feedback construtivo sobre posts
-- - Sistema de reconhecimento
-- - Menção de usuários específicos
-- - Pontuação diferenciada (maior valor)
-- - Notificações automáticas
-- 
-- Relacionamentos Implícitos:
-- - feedbacks.post_id → posts.id
-- - feedbacks.author_id → profiles.id
-- - feedbacks.mentioned_user_id → profiles.id
-- 
-- Validações:
-- - created_at obrigatório
-- - feedback_text opcional (permite feedback vazio)
-- - mentioned_user_id opcional
-- - Prevenção de auto-feedback
-- 
-- Diferenças das Outras Tabelas:
-- - Única com BIGINT como PK
-- - Única com created_at NOT NULL
-- - Defaults UUID em campos relacionais
-- - Sem CASCADE DELETE explícito
-- 
-- ============================================================================

