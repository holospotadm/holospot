-- ============================================================================
-- COMMENTS TABLE - Sistema de Comentários
-- ============================================================================
-- Tabela que armazena todos os comentários feitos em posts
-- Parte do sistema de interação social do HoloSpot
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.comments (
    -- Identificador único do comentário
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Referência ao post comentado
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    
    -- Referência ao usuário que fez o comentário
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Conteúdo do comentário
    content TEXT NOT NULL,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ÍNDICES DA TABELA COMMENTS
-- ============================================================================

-- Índice para busca por post (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_comments_post_id 
ON public.comments (post_id);

-- Índice para busca por usuário
CREATE INDEX IF NOT EXISTS idx_comments_user_id 
ON public.comments (user_id);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_comments_created_at 
ON public.comments (created_at DESC);

-- Índice composto para busca eficiente por post e data
CREATE INDEX IF NOT EXISTS idx_comments_post_created 
ON public.comments (post_id, created_at DESC);

-- ============================================================================
-- TRIGGERS DA TABELA COMMENTS
-- ============================================================================

-- Trigger para verificação automática de badges após comentário
CREATE TRIGGER auto_badge_check_bonus_comments 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger para operações seguras de inserção (pontos)
CREATE TRIGGER comment_insert_secure_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_insert_secure();

-- Trigger para operações seguras de deleção (pontos)
CREATE TRIGGER comment_delete_secure_trigger 
    AFTER DELETE ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_delete_secure();

-- Trigger para notificação correta
CREATE TRIGGER comment_notification_correto_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_notification_correto();

-- Trigger para notificação simplificada
CREATE TRIGGER comment_notify_only_trigger 
    AFTER INSERT ON public.comments 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_comment_notification_only();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.comments IS 
'Tabela que armazena todos os comentários feitos em posts.
Parte do sistema de interação social do HoloSpot.';

COMMENT ON COLUMN public.comments.id IS 'Identificador único do comentário (UUID)';
COMMENT ON COLUMN public.comments.post_id IS 'Referência ao post que foi comentado';
COMMENT ON COLUMN public.comments.user_id IS 'Referência ao usuário que fez o comentário';
COMMENT ON COLUMN public.comments.content IS 'Conteúdo textual do comentário';
COMMENT ON COLUMN public.comments.created_at IS 'Timestamp de quando o comentário foi criado';

-- ============================================================================
-- NOTAS SOBRE A TABELA COMMENTS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 5 campos simples e diretos
-- - UUID como chave primária com gen_random_uuid()
-- - Foreign keys para posts e profiles
-- - Conteúdo obrigatório (TEXT)
-- - Timestamp automático de criação
-- 
-- Relacionamentos:
-- - comments.post_id → posts.id (CASCADE DELETE)
-- - comments.user_id → profiles.id (CASCADE DELETE)
-- 
-- Sistema de Pontuação:
-- - Autor do comentário: +5 pontos
-- - Autor do post: +3 pontos (se diferente)
-- - Registrado em points_history
-- 
-- Sistema de Notificações:
-- - Notifica autor do post quando recebe comentário
-- - Sistema anti-spam com janela de 6 horas
-- - Mensagens padronizadas sem exclamações
-- 
-- Triggers Ativos (5 total):
-- 1. auto_badge_check_bonus_comments - Verificação de badges
-- 2. comment_insert_secure_trigger - Pontos na inserção
-- 3. comment_delete_secure_trigger - Pontos na deleção
-- 4. comment_notification_correto_trigger - Notificação principal
-- 5. comment_notify_only_trigger - Notificação simplificada
-- 
-- Funcionalidades:
-- - Comentários em posts (holofotes)
-- - Sistema de pontuação integrado
-- - Notificações automáticas
-- - Verificação de badges
-- - Deleção em cascata
-- 
-- Validações:
-- - Conteúdo obrigatório
-- - Referências válidas (FK)
-- - Prevenção de auto-notificação
-- - Controle de duplicatas
-- 
-- Performance:
-- - Índices otimizados para consultas comuns
-- - Busca por post (mais comum)
-- - Busca por usuário
-- - Ordenação por data
-- 
-- ============================================================================

