-- ============================================================================
-- AUDIT TRIGGERS - Sistema de Auditoria
-- ============================================================================
-- Triggers responsáveis por manter campos de auditoria atualizados
-- Função: update_updated_at_column()
-- ============================================================================

-- ============================================================================
-- BADGES - Updated At Trigger
-- ============================================================================
-- Atualiza automaticamente o campo updated_at quando badges são modificados
CREATE TRIGGER update_badges_updated_at 
    BEFORE UPDATE ON public.badges 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- USER_POINTS - Updated At Trigger  
-- ============================================================================
-- Atualiza automaticamente o campo updated_at quando pontos são modificados
CREATE TRIGGER update_user_points_updated_at 
    BEFORE UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- NOTAS SOBRE TRIGGERS DE AUDITORIA
-- ============================================================================
-- 
-- Função Utilizada: update_updated_at_column()
-- - Tipo: SECURITY INVOKER
-- - Execução: BEFORE UPDATE
-- - Propósito: Manter rastreabilidade de modificações
-- 
-- Tabelas Cobertas:
-- - badges: Rastreia mudanças em configurações de badges
-- - user_points: Rastreia mudanças em pontuações de usuários
-- 
-- Outras tabelas com updated_at que NÃO têm trigger:
-- - posts (updated_at manual)
-- - profiles (updated_at manual)
-- - user_badges (não tem updated_at)
-- 
-- ============================================================================

