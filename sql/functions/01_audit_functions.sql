-- ============================================================================
-- AUDIT FUNCTIONS - Funções de Auditoria
-- ============================================================================
-- Funções responsáveis por manter campos de auditoria atualizados
-- Utilizadas pelos triggers de auditoria
-- ============================================================================

-- ============================================================================
-- UPDATE_UPDATED_AT_COLUMN - Atualização Automática de Timestamp
-- ============================================================================
-- Função genérica para atualizar automaticamente campos updated_at
-- Utilizada por: update_badges_updated_at, update_user_points_updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.update_updated_at_column() IS 
'Função genérica para atualizar automaticamente o campo updated_at.
Utilizada pelos triggers de auditoria nas tabelas badges e user_points.
Execução: BEFORE UPDATE
Segurança: SECURITY INVOKER
Volatilidade: VOLATILE';

-- ============================================================================
-- NOTAS SOBRE FUNÇÕES DE AUDITORIA
-- ============================================================================
-- 
-- Propósito:
-- - Manter rastreabilidade de modificações
-- - Atualizar automaticamente campos de timestamp
-- - Garantir consistência temporal nos dados
-- 
-- Tabelas Afetadas:
-- - badges: Rastreia mudanças em configurações de badges
-- - user_points: Rastreia mudanças em pontuações de usuários
-- 
-- Implementação:
-- - Função simples e eficiente
-- - Executa antes da atualização (BEFORE UPDATE)
-- - Não requer parâmetros
-- - Retorna NEW com updated_at modificado
-- 
-- Vantagens:
-- - Reutilizável para qualquer tabela com updated_at
-- - Performance otimizada
-- - Manutenção centralizada
-- - Consistência garantida
-- 
-- Uso nos Triggers:
-- CREATE TRIGGER update_[tabela]_updated_at 
--     BEFORE UPDATE ON public.[tabela] 
--     FOR EACH ROW 
--     EXECUTE FUNCTION update_updated_at_column();
-- 
-- ============================================================================

