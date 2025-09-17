-- ============================================================================
-- POSTS TABLE - Sistema de Posts/Holofotes
-- ============================================================================
-- Tabela principal que armazena todos os posts (holofotes) do sistema
-- Núcleo do sistema de reconhecimento e gratidão
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.posts (
    -- Identificador único do post
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usuário que criou o post
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Nome da pessoa celebrada/destacada (obrigatório)
    celebrated_person_name TEXT NOT NULL,
    
    -- Conteúdo do post (obrigatório)
    content TEXT NOT NULL,
    
    -- Tipo do post (default: gratidão)
    type TEXT DEFAULT 'gratidão',
    
    -- URL da foto anexada (opcional)
    photo_url TEXT,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Timestamp de última atualização
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Nome da pessoa (campo adicional)
    person_name TEXT,
    
    -- História/contexto do post
    story TEXT,
    
    -- Tipo de destaque/holofote
    highlight_type TEXT,
    
    -- ID do usuário mencionado (para notificações)
    mentioned_user_id UUID
);

-- ============================================================================
-- ÍNDICES DA TABELA POSTS
-- ============================================================================

-- Índice para busca por usuário autor
CREATE INDEX IF NOT EXISTS idx_posts_user_id 
ON public.posts (user_id);

-- Índice para ordenação por data de criação (consulta mais comum)
CREATE INDEX IF NOT EXISTS idx_posts_created_at 
ON public.posts (created_at DESC);

-- Índice para busca por tipo de post
CREATE INDEX IF NOT EXISTS idx_posts_type 
ON public.posts (type);

-- Índice para busca por usuário mencionado
CREATE INDEX IF NOT EXISTS idx_posts_mentioned_user_id 
ON public.posts (mentioned_user_id);

-- Índice para busca por tipo de destaque
CREATE INDEX IF NOT EXISTS idx_posts_highlight_type 
ON public.posts (highlight_type);

-- Índice composto para busca eficiente por usuário e data
CREATE INDEX IF NOT EXISTS idx_posts_user_created 
ON public.posts (user_id, created_at DESC);

-- Índice para busca textual no nome da pessoa celebrada
CREATE INDEX IF NOT EXISTS idx_posts_celebrated_person_name 
ON public.posts USING gin(to_tsvector('portuguese', celebrated_person_name));

-- Índice para busca textual no conteúdo
CREATE INDEX IF NOT EXISTS idx_posts_content_search 
ON public.posts USING gin(to_tsvector('portuguese', content));

-- ============================================================================
-- TRIGGERS DA TABELA POSTS
-- ============================================================================

-- Trigger para verificação automática de badges após post
CREATE TRIGGER auto_badge_check_bonus_posts 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION auto_check_badges_with_bonus_after_action();

-- Trigger para operações seguras de inserção (pontos)
CREATE TRIGGER post_insert_secure_trigger 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_post_insert_secure();

-- Trigger para notificação de holofote/menção
CREATE TRIGGER holofote_notification_trigger 
    AFTER INSERT ON public.posts 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_holofote_notification();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.posts IS 
'Tabela principal que armazena todos os posts (holofotes) do sistema.
Núcleo do sistema de reconhecimento e gratidão do HoloSpot.';

COMMENT ON COLUMN public.posts.id IS 'Identificador único do post (UUID)';
COMMENT ON COLUMN public.posts.user_id IS 'Usuário que criou o post';
COMMENT ON COLUMN public.posts.celebrated_person_name IS 'Nome da pessoa celebrada/destacada no post';
COMMENT ON COLUMN public.posts.content IS 'Conteúdo textual do post';
COMMENT ON COLUMN public.posts.type IS 'Tipo do post (gratidão, reconhecimento, etc.)';
COMMENT ON COLUMN public.posts.photo_url IS 'URL da foto anexada ao post';
COMMENT ON COLUMN public.posts.created_at IS 'Timestamp de criação do post';
COMMENT ON COLUMN public.posts.updated_at IS 'Timestamp de última atualização do post';
COMMENT ON COLUMN public.posts.person_name IS 'Nome da pessoa (campo adicional para flexibilidade)';
COMMENT ON COLUMN public.posts.story IS 'História ou contexto adicional do post';
COMMENT ON COLUMN public.posts.highlight_type IS 'Tipo específico de destaque ou holofote';
COMMENT ON COLUMN public.posts.mentioned_user_id IS 'ID do usuário mencionado (para notificações)';

-- ============================================================================
-- NOTAS SOBRE A TABELA POSTS
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 12 campos com funcionalidades específicas do HoloSpot
-- - UUID como chave primária com gen_random_uuid()
-- - Foreign key para profiles (user_id)
-- - Campos obrigatórios: celebrated_person_name, content
-- - Campos opcionais para flexibilidade e contexto
-- 
-- Relacionamentos:
-- - posts.user_id → profiles.id (CASCADE DELETE)
-- - Relacionamento implícito via mentioned_user_id
-- 
-- Campos Específicos do HoloSpot:
-- - celebrated_person_name: Nome da pessoa destacada
-- - person_name: Campo adicional para nome
-- - story: História ou contexto do reconhecimento
-- - highlight_type: Tipo específico de holofote
-- - mentioned_user_id: Para sistema de menções
-- 
-- Sistema de Pontuação:
-- - Autor do post: +10 pontos
-- - Usuário mencionado: +5 pontos (se houver)
-- - Registrado em points_history
-- 
-- Sistema de Notificações:
-- - Notifica usuário mencionado quando é destacado
-- - Sistema anti-spam com janela de 1 hora
-- - Mensagens padronizadas para holofotes
-- 
-- Triggers Ativos (3 total):
-- 1. auto_badge_check_bonus_posts - Verificação de badges
-- 2. post_insert_secure_trigger - Pontos na inserção
-- 3. holofote_notification_trigger - Notificação de menção
-- 
-- Funcionalidades:
-- - Sistema de holofotes/reconhecimento
-- - Menções de usuários
-- - Anexo de fotos
-- - Categorização por tipo
-- - Busca textual avançada
-- 
-- Tipos de Post Comuns:
-- - gratidão: Agradecimentos (default)
-- - reconhecimento: Reconhecimento profissional
-- - celebração: Celebrações e conquistas
-- - inspiração: Posts inspiracionais
-- 
-- Busca e Performance:
-- - Índices para busca textual em português
-- - Busca eficiente por autor e data
-- - Busca por pessoa celebrada
-- - Busca por tipo de post
-- 
-- Validações:
-- - celebrated_person_name obrigatório
-- - content obrigatório
-- - Referências válidas (FK)
-- - Prevenção de auto-menção
-- 
-- Integridade:
-- - Foreign key garante usuário válido
-- - Deleção em cascata mantém consistência
-- - Campos obrigatórios garantem dados mínimos
-- - Timestamps automáticos
-- 
-- Manutenção:
-- - Tabela de crescimento contínuo
-- - Monitoramento de performance de busca
-- - Otimização de índices textuais
-- - Backup regular para preservar conteúdo
-- 
-- ============================================================================

