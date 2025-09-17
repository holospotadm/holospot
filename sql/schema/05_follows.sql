-- ============================================================================
-- FOLLOWS TABLE - Sistema de Seguidores
-- ============================================================================
-- Tabela que gerencia relacionamentos de seguidor/seguindo entre usuários
-- Sistema de rede social do HoloSpot
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.follows (
    -- Identificador único do relacionamento
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usuário que está seguindo (quem segue)
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Usuário que está sendo seguido (quem é seguido)
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Timestamp de quando começou a seguir
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- CONSTRAINTS DA TABELA FOLLOWS
-- ============================================================================

-- Constraint para evitar auto-follow (usuário seguir a si mesmo)
ALTER TABLE public.follows 
ADD CONSTRAINT check_no_self_follow 
CHECK (follower_id != following_id);

-- Constraint única para evitar follows duplicados
ALTER TABLE public.follows 
ADD CONSTRAINT unique_follow_relationship 
UNIQUE (follower_id, following_id);

-- ============================================================================
-- ÍNDICES DA TABELA FOLLOWS
-- ============================================================================

-- Índice para busca por seguidor (quem segue)
CREATE INDEX IF NOT EXISTS idx_follows_follower_id 
ON public.follows (follower_id);

-- Índice para busca por seguido (quem é seguido)
CREATE INDEX IF NOT EXISTS idx_follows_following_id 
ON public.follows (following_id);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_follows_created_at 
ON public.follows (created_at DESC);

-- Índice composto para verificação rápida de relacionamento
CREATE INDEX IF NOT EXISTS idx_follows_relationship 
ON public.follows (follower_id, following_id);

-- ============================================================================
-- TRIGGERS DA TABELA FOLLOWS
-- ============================================================================

-- Trigger para notificação quando alguém é seguido
CREATE TRIGGER follow_notification_correto_trigger 
    AFTER INSERT ON public.follows 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_follow_notification_correto();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.follows IS 
'Tabela que gerencia relacionamentos de seguidor/seguindo entre usuários.
Sistema de rede social do HoloSpot.';

COMMENT ON COLUMN public.follows.id IS 'Identificador único do relacionamento de follow';
COMMENT ON COLUMN public.follows.follower_id IS 'Usuário que está seguindo (quem segue)';
COMMENT ON COLUMN public.follows.following_id IS 'Usuário que está sendo seguido (quem é seguido)';
COMMENT ON COLUMN public.follows.created_at IS 'Timestamp de quando o relacionamento foi criado';

-- ============================================================================
-- NOTAS SOBRE A TABELA FOLLOWS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 4 campos simples e diretos
-- - UUID como chave primária com gen_random_uuid()
-- - Foreign keys obrigatórias para profiles
-- - Timestamp automático de criação
-- 
-- Relacionamentos:
-- - follows.follower_id → profiles.id (CASCADE DELETE)
-- - follows.following_id → profiles.id (CASCADE DELETE)
-- 
-- Constraints Importantes:
-- - Prevenção de auto-follow (usuário seguir a si mesmo)
-- - Unicidade de relacionamento (evita follows duplicados)
-- - Campos obrigatórios (NOT NULL)
-- 
-- Sistema de Notificações:
-- - Notifica usuário quando é seguido
-- - Sistema anti-spam com janela de 24 horas
-- - Mensagens padronizadas sem exclamações
-- 
-- Triggers Ativos (1 total):
-- 1. follow_notification_correto_trigger - Notificação de novo seguidor
-- 
-- Funcionalidades:
-- - Sistema de seguidores/seguindo
-- - Rede social básica
-- - Notificações de novos seguidores
-- - Prevenção de relacionamentos inválidos
-- 
-- Consultas Comuns:
-- - Listar seguidores de um usuário
-- - Listar quem um usuário segue
-- - Verificar se A segue B
-- - Contar seguidores/seguindo
-- 
-- Validações:
-- - Não pode seguir a si mesmo
-- - Não pode seguir o mesmo usuário duas vezes
-- - Referências válidas para profiles
-- - Deleção em cascata
-- 
-- Performance:
-- - Índices otimizados para consultas bidirecionais
-- - Busca eficiente por seguidor ou seguido
-- - Verificação rápida de relacionamento
-- - Ordenação por data de criação
-- 
-- Integridade:
-- - Foreign keys garantem usuários válidos
-- - Constraints previnem dados inconsistentes
-- - Deleção em cascata mantém consistência
-- - Unicidade evita duplicatas
-- 
-- ============================================================================

