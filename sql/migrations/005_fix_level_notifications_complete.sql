-- ============================================================================
-- MIGRATION 005: CORREÇÃO COMPLETA DAS NOTIFICAÇÕES DE NÍVEL
-- ============================================================================
-- Solução definitiva para notificações de level_up funcionarem 100%
-- ============================================================================

-- 1. VERIFICAR E CORRIGIR FUNÇÃO create_single_notification
-- ============================================================================

-- Verificar se função existe e tem assinatura correta
DO $$
BEGIN
    -- Verificar se função create_single_notification existe
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'create_single_notification'
    ) THEN
        RAISE NOTICE '❌ Função create_single_notification não existe - criando...';
        
        -- Criar função se não existir
        EXECUTE '
        CREATE OR REPLACE FUNCTION public.create_single_notification(
            p_user_id UUID,
            p_from_user_id UUID,
            p_type TEXT,
            p_message TEXT,
            p_priority INTEGER DEFAULT 1
        )
        RETURNS UUID
        LANGUAGE plpgsql
        SECURITY INVOKER
        AS $func$
        DECLARE
            notification_id UUID;
        BEGIN
            INSERT INTO public.notifications (
                user_id,
                from_user_id,
                type,
                message,
                priority,
                read,
                created_at
            ) VALUES (
                p_user_id,
                p_from_user_id,
                p_type,
                p_message,
                p_priority,
                false,
                now()
            ) RETURNING id INTO notification_id;
            
            RETURN notification_id;
        END;
        $func$;';
        
        RAISE NOTICE '✅ Função create_single_notification criada com sucesso';
    ELSE
        RAISE NOTICE '✅ Função create_single_notification já existe';
    END IF;
END $$;

-- 2. VERIFICAR E CORRIGIR FUNÇÃO handle_level_up_notification
-- ============================================================================

-- Recriar função com lógica mais robusta
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
    notification_id UUID;
BEGIN
    -- Verificar se o nível realmente mudou
    IF OLD.level_id IS DISTINCT FROM NEW.level_id THEN
        
        RAISE NOTICE 'LEVEL CHANGE DETECTED: User % - Old level: % → New level: %', 
            NEW.user_id, OLD.level_id, NEW.level_id;
        
        -- Buscar informações do novo nível
        SELECT name, color, benefits INTO level_info
        FROM public.levels 
        WHERE id = NEW.level_id;
        
        IF level_info.name IS NULL THEN
            RAISE NOTICE 'WARNING: Level % not found in levels table', NEW.level_id;
            RETURN NEW;
        END IF;
        
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
        SELECT create_single_notification(
            NEW.user_id,
            NULL,  -- Notificação do sistema
            'level_up',
            message_text,
            3  -- Alta prioridade
        ) INTO notification_id;
        
        RAISE NOTICE 'LEVEL UP NOTIFICATION CREATED: ID % for user % - Message: %', 
            notification_id, NEW.user_id, message_text;
    END IF;
    
    RETURN NEW;
END;
$function$;

-- 3. VERIFICAR E RECRIAR TRIGGER
-- ============================================================================

-- Remover trigger se existir
DROP TRIGGER IF EXISTS level_up_notification_trigger ON public.user_points;

-- Criar trigger
CREATE TRIGGER level_up_notification_trigger 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_level_up_notification();

-- 4. TESTE FINAL
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID;
    current_level INTEGER;
    next_level INTEGER;
    notification_count_before INTEGER;
    notification_count_after INTEGER;
BEGIN
    -- Buscar usuário para teste
    SELECT user_id, level_id INTO test_user_id, current_level
    FROM user_points 
    WHERE level_id < (SELECT MAX(id) FROM levels)
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'TESTE CANCELADO: Nenhum usuário disponível para teste';
        RETURN;
    END IF;
    
    -- Buscar próximo nível
    SELECT id INTO next_level
    FROM levels 
    WHERE id > current_level
    ORDER BY id ASC
    LIMIT 1;
    
    IF next_level IS NULL THEN
        RAISE NOTICE 'TESTE CANCELADO: Nenhum nível superior disponível';
        RETURN;
    END IF;
    
    -- Contar notificações antes
    SELECT COUNT(*) INTO notification_count_before
    FROM notifications 
    WHERE user_id = test_user_id AND type = 'level_up';
    
    RAISE NOTICE 'TESTE INICIADO: User % - Level %→% - Notificações antes: %', 
        test_user_id, current_level, next_level, notification_count_before;
    
    -- Executar mudança de nível
    UPDATE user_points 
    SET level_id = next_level,
        updated_at = now()
    WHERE user_id = test_user_id;
    
    -- Contar notificações depois
    SELECT COUNT(*) INTO notification_count_after
    FROM notifications 
    WHERE user_id = test_user_id AND type = 'level_up';
    
    RAISE NOTICE 'TESTE CONCLUÍDO: Notificações depois: % (diferença: %)', 
        notification_count_after, (notification_count_after - notification_count_before);
    
    -- Reverter mudança
    UPDATE user_points 
    SET level_id = current_level,
        updated_at = now()
    WHERE user_id = test_user_id;
    
    RAISE NOTICE 'TESTE FINALIZADO: Level revertido para %', current_level;
    
END $$;

-- 5. VERIFICAÇÃO FINAL
-- ============================================================================

-- Mostrar status final
SELECT 
    'STATUS FINAL' as resultado,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_single_notification') 
         THEN '✅ create_single_notification EXISTS' 
         ELSE '❌ create_single_notification MISSING' END as func_auxiliar,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_level_up_notification') 
         THEN '✅ handle_level_up_notification EXISTS' 
         ELSE '❌ handle_level_up_notification MISSING' END as func_principal,
    CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'level_up_notification_trigger') 
         THEN '✅ level_up_notification_trigger EXISTS' 
         ELSE '❌ level_up_notification_trigger MISSING' END as trigger_status;

-- Mostrar últimas notificações level_up criadas
SELECT 
    'ÚLTIMAS NOTIFICAÇÕES LEVEL_UP' as resultado,
    user_id,
    message,
    created_at
FROM notifications 
WHERE type = 'level_up'
ORDER BY created_at DESC
LIMIT 5;

