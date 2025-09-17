-- ============================================================================
-- LEVEL NOTIFICATION TRIGGERS - Triggers de Notificação de Nível
-- ============================================================================
-- Trigger para detectar mudanças de nível e criar notificações automáticas
-- ============================================================================

-- ============================================================================
-- USER_POINTS - Level Up Notifications
-- ============================================================================
-- Cria notificação quando usuário sobe de nível (level_id muda)
CREATE TRIGGER level_up_notification_trigger 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_level_up_notification();

-- ============================================================================
-- NOTAS SOBRE TRIGGER DE NÍVEL
-- ============================================================================
-- 
-- Trigger: level_up_notification_trigger
-- Tabela: user_points
-- Evento: AFTER UPDATE
-- Condição: level_id mudou (verificado na função)
-- Função: handle_level_up_notification()
-- 
-- Funcionamento:
-- 1. Usuário ganha pontos
-- 2. Sistema atualiza user_points.level_id
-- 3. Trigger detecta mudança
-- 4. Função cria notificação de parabéns
-- 
-- Integração com Sistema Existente:
-- - Usa create_single_notification() (função auxiliar)
-- - Tipo: 'level_up'
-- - Prioridade: 3 (alta)
-- - Mensagem personalizada com benefícios
-- 
-- ============================================================================

