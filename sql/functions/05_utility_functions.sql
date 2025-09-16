-- ============================================================================
-- UTILITY FUNCTIONS - Funções Utilitárias
-- ============================================================================
-- Funções de suporte e conveniência para automações do sistema
-- ============================================================================

-- ============================================================================
-- USERNAME GENERATION - Geração Automática de Username
-- ============================================================================

CREATE OR REPLACE FUNCTION public.generate_username_from_email()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    -- Se username não foi fornecido e email existe, gerar automaticamente
    IF NEW.username IS NULL AND NEW.email IS NOT NULL THEN
        NEW.username = SPLIT_PART(NEW.email, '@', 1);
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.generate_username_from_email() IS 
'Gera automaticamente username baseado no email do usuário.
Extrai a parte antes do @ do email como username.
Utilizada pelo trigger trigger_generate_username na tabela profiles.
Execução: BEFORE INSERT OR UPDATE
Segurança: SECURITY INVOKER
Volatilidade: VOLATILE';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES UTILITÁRIAS
-- ============================================================================
-- 
-- Funcionalidade do Username Generator:
-- 
-- 1. EXTRAÇÃO AUTOMÁTICA:
--    - Pega a parte antes do @ do email
--    - Aplica apenas se username estiver NULL
--    - Não sobrescreve usernames existentes
-- 
-- 2. EXEMPLOS DE GERAÇÃO:
--    - joao.silva@email.com → joaosilva (após remoção do ponto)
--    - maria123@gmail.com → maria123
--    - user@domain.com → user
--    - admin@holospot.com → admin
-- 
-- 3. LIMITAÇÕES ATUAIS:
--    - Não remove caracteres especiais (implementar se necessário)
--    - Não verifica unicidade (implementar se necessário)
--    - Não aplica transformações de case
--    - Não adiciona números sequenciais para duplicatas
-- 
-- 4. MELHORIAS FUTURAS SUGERIDAS:
--    - Verificação de unicidade com sufixos numéricos
--    - Remoção de caracteres especiais
--    - Conversão para lowercase
--    - Validação de comprimento mínimo/máximo
--    - Prevenção de usernames reservados
-- 
-- 5. INTEGRAÇÃO COM SISTEMA:
--    - Username usado para menções (@username)
--    - Exibido em perfis públicos
--    - Usado em URLs de perfil (/profile/username)
--    - Facilita identificação de usuários
--    - Melhora UX em menções e buscas
-- 
-- 6. REGRAS DE NEGÓCIO:
--    - Username deve ser único (validar externamente)
--    - Máximo 50 caracteres (conforme schema)
--    - Apenas letras, números e underscore (implementar)
--    - Não pode começar com número (implementar)
--    - Case insensitive para verificação (implementar)
-- 
-- 7. TRIGGER ASSOCIADO:
--    CREATE TRIGGER trigger_generate_username 
--        BEFORE INSERT OR UPDATE ON public.profiles 
--        FOR EACH ROW 
--        EXECUTE FUNCTION generate_username_from_email();
-- 
-- 8. EXEMPLO DE USO:
--    INSERT INTO profiles (email, name) 
--    VALUES ('joao@email.com', 'João Silva');
--    -- Resultado: username = 'joao' (gerado automaticamente)
-- 
-- 9. VERSÃO MELHORADA (FUTURA):
--    - Implementar função generate_unique_username_from_email()
--    - Adicionar validações de caracteres
--    - Incluir sistema de sufixos para duplicatas
--    - Adicionar logs de geração
-- 
-- ============================================================================

