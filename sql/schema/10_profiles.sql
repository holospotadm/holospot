-- ============================================================================
-- PROFILES TABLE - Perfis de Usuários
-- ============================================================================
-- Tabela principal que armazena informações dos usuários do sistema
-- Base para autenticação e perfis públicos
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    -- Identificador único do usuário (sem default, gerenciado externamente)
    id UUID PRIMARY KEY,
    
    -- Email do usuário
    email TEXT,
    
    -- Nome completo do usuário
    name TEXT,
    
    -- URL do avatar/foto do perfil
    avatar_url TEXT,
    
    -- Timestamp de criação
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Timestamp de última atualização
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Username único para menções e URLs
    username VARCHAR(50)
);

-- ============================================================================
-- CONSTRAINTS DA TABELA PROFILES
-- ============================================================================

-- Constraint única para email (se usado)
ALTER TABLE public.profiles 
ADD CONSTRAINT unique_profiles_email 
UNIQUE (email);

-- Constraint única para username (se usado)
ALTER TABLE public.profiles 
ADD CONSTRAINT unique_profiles_username 
UNIQUE (username);

-- ============================================================================
-- ÍNDICES DA TABELA PROFILES
-- ============================================================================

-- Índice para busca por email
CREATE INDEX IF NOT EXISTS idx_profiles_email 
ON public.profiles (email);

-- Índice para busca por username
CREATE INDEX IF NOT EXISTS idx_profiles_username 
ON public.profiles (username);

-- Índice para busca por nome
CREATE INDEX IF NOT EXISTS idx_profiles_name 
ON public.profiles USING gin(to_tsvector('portuguese', name));

-- Índice para ordenação por data de criação
CREATE INDEX IF NOT EXISTS idx_profiles_created_at 
ON public.profiles (created_at DESC);

-- ============================================================================
-- TRIGGERS DA TABELA PROFILES
-- ============================================================================

-- Trigger para geração automática de username baseado no email
CREATE TRIGGER trigger_generate_username 
    BEFORE INSERT OR UPDATE ON public.profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION generate_username_from_email();

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.profiles IS 
'Tabela principal que armazena informações dos usuários do sistema.
Base para autenticação e perfis públicos do HoloSpot.';

COMMENT ON COLUMN public.profiles.id IS 'Identificador único do usuário (UUID, gerenciado externamente)';
COMMENT ON COLUMN public.profiles.email IS 'Email do usuário para autenticação e comunicação';
COMMENT ON COLUMN public.profiles.name IS 'Nome completo do usuário exibido no perfil';
COMMENT ON COLUMN public.profiles.avatar_url IS 'URL da foto de perfil/avatar do usuário';
COMMENT ON COLUMN public.profiles.created_at IS 'Timestamp de criação do perfil';
COMMENT ON COLUMN public.profiles.updated_at IS 'Timestamp de última atualização do perfil';
COMMENT ON COLUMN public.profiles.username IS 'Username único para menções (@username) e URLs de perfil';

-- ============================================================================
-- NOTAS SOBRE A TABELA PROFILES
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 7 campos simples e essenciais
-- - UUID como chave primária (sem default, gerenciado externamente)
-- - Todos os campos opcionais (exceto id)
-- - Username limitado a 50 caracteres
-- - Timestamps automáticos
-- 
-- Características Especiais:
-- - ID sem default (provavelmente gerenciado pelo Supabase Auth)
-- - Todos os campos nullable (flexibilidade)
-- - Username para sistema de menções
-- - Integração com sistema de autenticação
-- 
-- Relacionamentos (Referenciada por):
-- - comments.user_id → profiles.id
-- - posts.user_id → profiles.id
-- - reactions.user_id → profiles.id
-- - follows.follower_id → profiles.id
-- - follows.following_id → profiles.id
-- - notifications.user_id → profiles.id
-- - notifications.from_user_id → profiles.id
-- - user_badges.user_id → profiles.id
-- - user_points.user_id → profiles.id
-- - user_streaks.user_id → profiles.id
-- - points_history.user_id → profiles.id
-- 
-- Sistema de Username:
-- - Geração automática baseada no email
-- - Usado para menções (@username)
-- - URLs de perfil (/profile/username)
-- - Unicidade garantida por constraint
-- 
-- Triggers Ativos (1 total):
-- 1. trigger_generate_username - Geração automática de username
-- 
-- Funcionalidades:
-- - Perfis públicos de usuários
-- - Sistema de menções
-- - Autenticação integrada
-- - Avatars/fotos de perfil
-- - Busca por nome e username
-- 
-- Validações:
-- - Email único (se fornecido)
-- - Username único (se fornecido)
-- - Referências válidas em outras tabelas
-- - Geração automática de username
-- 
-- Busca e Performance:
-- - Índice para busca textual em nome
-- - Busca eficiente por email e username
-- - Ordenação por data de criação
-- - Constraints de unicidade
-- 
-- Integridade:
-- - Tabela central do sistema
-- - Referenciada por todas as outras tabelas
-- - Constraints de unicidade
-- - Deleção em cascata em tabelas dependentes
-- 
-- Integração com Supabase Auth:
-- - ID gerenciado externamente (Auth)
-- - Email sincronizado com Auth
-- - Perfil complementar aos dados de Auth
-- - Flexibilidade para dados opcionais
-- 
-- Manutenção:
-- - Tabela crítica do sistema
-- - Backup essencial
-- - Monitoramento de integridade
-- - Sincronização com sistema de Auth
-- 
-- ============================================================================

