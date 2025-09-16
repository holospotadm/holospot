-- ============================================================================
-- UTILITY TRIGGERS - Triggers Utilitários
-- ============================================================================
-- Triggers responsáveis por funcionalidades auxiliares e automações
-- Funções de suporte e conveniência
-- ============================================================================

-- ============================================================================
-- PROFILES - Username Generation
-- ============================================================================
-- Gera automaticamente username baseado no email quando perfil é criado/atualizado
CREATE TRIGGER trigger_generate_username 
    BEFORE INSERT OR UPDATE ON public.profiles 
    FOR EACH ROW 
    EXECUTE FUNCTION generate_username_from_email();

-- ============================================================================
-- NOTAS SOBRE TRIGGERS UTILITÁRIOS
-- ============================================================================
-- 
-- Função Utilizada:
-- - generate_username_from_email(): Gera username a partir do email
-- 
-- Tipo: SECURITY INVOKER
-- Execução: BEFORE INSERT OR UPDATE
-- 
-- Funcionalidade do Username Generator:
-- 
-- 1. EXTRAÇÃO DO EMAIL:
--    - Pega a parte antes do @ do email
--    - Remove caracteres especiais
--    - Converte para lowercase
-- 
-- 2. VALIDAÇÃO DE UNICIDADE:
--    - Verifica se username já existe
--    - Adiciona números sequenciais se necessário
--    - Garante unicidade na tabela profiles
-- 
-- 3. APLICAÇÃO AUTOMÁTICA:
--    - Executa em INSERT (novos usuários)
--    - Executa em UPDATE (mudança de email)
--    - Só atualiza se username estiver vazio ou nulo
-- 
-- Exemplos de Geração:
-- - joao.silva@email.com → joaosilva
-- - maria123@gmail.com → maria123
-- - user@domain.com → user (se disponível)
-- - user@domain.com → user1 (se user já existe)
-- 
-- Regras de Negócio:
-- - Username deve ser único
-- - Máximo 50 caracteres (conforme schema)
-- - Apenas letras, números e underscore
-- - Não pode começar com número
-- - Case insensitive para verificação
-- 
-- Integração com Sistema:
-- - Username usado para menções (@username)
-- - Exibido em perfis públicos
-- - Usado em URLs de perfil
-- - Facilita identificação de usuários
-- 
-- ============================================================================

