-- ============================================================================
-- LEVEL NOTIFICATION FUNCTIONS - Sistema de Notificação de Níveis
-- ============================================================================
-- Sistema completo para notificar usuários quando sobem de nível
-- Inclui trigger e função para mudanças na tabela user_points
-- ============================================================================

-- ============================================================================
-- HANDLE_LEVEL_UP_NOTIFICATION - Função Principal
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_level_up_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
DECLARE
    old_level_name TEXT;
    new_level_name TEXT;
    level_info RECORD;
    message_text TEXT;
BEGIN
    -- Verificar se o nível realmente mudou
    IF OLD.level_id IS DISTINCT FROM NEW.level_id THEN
        
        -- Buscar informações do novo nível
        SELECT name, color, benefits INTO level_info
        FROM public.levels 
        WHERE id = NEW.level_id;
        
        -- Buscar nome do nível anterior (se existir)
        IF OLD.level_id IS NOT NULL THEN
            SELECT name INTO old_level_name
            FROM public.levels 
            WHERE id = OLD.level_id;
        ELSE
            old_level_name := 'Iniciante';
        END IF;
        
        -- Montar mensagem de parabéns
        message_text := '🎉 Parabéns! Você subiu para o nível "' || level_info.name || '"';
        
        -- Adicionar informações de benefícios se existirem
        IF level_info.benefits IS NOT NULL AND level_info.benefits != '' THEN
            message_text := message_text || ' - ' || level_info.benefits;
        END IF;
        
        -- Criar notificação de nível
        PERFORM create_single_notification(
            NEW.user_id,
            NULL,  -- Notificação do sistema
            'level_up',
            message_text,
            3  -- Alta prioridade
        );
        
        RAISE NOTICE 'LEVEL UP: % subiu de % (ID:%) para % (ID:%)', 
            NEW.user_id, old_level_name, OLD.level_id, level_info.name, NEW.level_id;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.handle_level_up_notification() IS 
'Cria notificações quando usuários sobem de nível.
Trigger: AFTER UPDATE ON user_points
Condição: level_id mudou
Inclui informações do novo nível e benefícios.';

-- ============================================================================
-- NOTAS SOBRE NOTIFICAÇÕES DE NÍVEL
-- ============================================================================
-- 
-- Funcionamento:
-- 1. Trigger detecta mudança em user_points.level_id
-- 2. Função busca informações do novo nível
-- 3. Monta mensagem personalizada com benefícios
-- 4. Cria notificação usando create_single_notification()
-- 
-- Informações Incluídas:
-- - Nome do novo nível
-- - Benefícios do nível (se existirem)
-- - Emoji de celebração (🎉)
-- - Alta prioridade (3)
-- 
-- Tipo de Notificação:
-- - type: 'level_up'
-- - from_user_id: NULL (sistema)
-- - priority: 3 (alta)
-- 
-- Dependências:
-- - Tabela levels (name, benefits)
-- - Função create_single_notification()
-- - Trigger level_up_notification_trigger (será criado)
-- 
-- ============================================================================

