-- ============================================================================
-- MIGRATION 003: Corrigir Sistema de Notificações (VERSÃO CORRIGIDA)
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Criar funções auxiliares faltantes e implementar notificações de nível
-- Problemas corrigidos:
-- 1. create_single_notification() - Faltando (usada por badges)
-- 2. notify_streak_milestone_correct() - Faltando (usada por streaks)
-- 3. Sistema de notificação de nível - Não implementado
-- ============================================================================

-- Verificar estado atual
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 VERIFICANDO ESTADO ATUAL DAS NOTIFICAÇÕES...';
    RAISE NOTICE '';
END $$;

-- Verificar se funções auxiliares existem
SELECT 
    'FUNÇÕES AUXILIARES:' as info,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_single_notification'
    ) THEN '⚠️ create_single_notification EXISTS (será recriada)'
    ELSE '❌ create_single_notification MISSING' END as create_single,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'notify_streak_milestone_correct'
    ) THEN '⚠️ notify_streak_milestone_correct EXISTS (será recriada)'
    ELSE '❌ notify_streak_milestone_correct MISSING' END as notify_streak;

-- Remover funções existentes se necessário
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🗑️ REMOVENDO FUNÇÕES EXISTENTES (SE NECESSÁRIO)...';
END $$;

-- Remover função create_single_notification se existir
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, UUID, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, TEXT, TEXT);

-- Remover função notify_streak_milestone_correct se existir
DROP FUNCTION IF EXISTS public.notify_streak_milestone_correct(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.notify_streak_milestone_correct(UUID, INTEGER);

-- Remover função de nível se existir
DROP FUNCTION IF EXISTS public.handle_level_up_notification();

-- Remover trigger de nível se existir
DROP TRIGGER IF EXISTS level_up_notification_trigger ON public.user_points;

-- Criar funções auxiliares faltantes
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 CRIANDO FUNÇÕES AUXILIARES FALTANTES...';
END $$;

-- 1. CREATE_SINGLE_NOTIFICATION - Função Auxiliar Principal
CREATE OR REPLACE FUNCTION public.create_single_notification(
    p_user_id UUID,
    p_from_user_id UUID,
    p_type TEXT,
    p_message TEXT,
    p_priority INTEGER DEFAULT 1
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
BEGIN
    -- Criar notificação simples sem agrupamento
    INSERT INTO public.notifications (
        user_id,
        from_user_id,
        type,
        message,
        read,
        created_at,
        group_key,
        group_count,
        group_data
    ) VALUES (
        p_user_id,
        p_from_user_id,
        p_type,
        p_message,
        false,
        NOW(),
        NULL,  -- Sem agrupamento para notificações simples
        1,
        NULL
    );
    
    RAISE NOTICE 'NOTIFICAÇÃO CRIADA: % para %', p_type, p_user_id;
END;
$function$;

-- 2. NOTIFY_STREAK_MILESTONE_CORRECT - Função Específica para Streaks
CREATE OR REPLACE FUNCTION public.notify_streak_milestone_correct(
    p_user_id UUID,
    p_milestone_days INTEGER,
    p_bonus_points INTEGER DEFAULT 0
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
DECLARE
    message_text TEXT;
    milestone_emoji TEXT;
BEGIN
    -- Definir emoji baseado no milestone
    CASE p_milestone_days
        WHEN 7 THEN milestone_emoji := '🔥';
        WHEN 30 THEN milestone_emoji := '⚡';
        WHEN 182 THEN milestone_emoji := '🌟';
        WHEN 365 THEN milestone_emoji := '👑';
        ELSE milestone_emoji := '🎯';
    END CASE;
    
    -- Montar mensagem baseada nos pontos bônus
    IF p_bonus_points > 0 THEN
        message_text := milestone_emoji || ' Incrível! Você atingiu ' || p_milestone_days || ' dias de sequência e ganhou ' || p_bonus_points || ' pontos bônus';
    ELSE
        message_text := milestone_emoji || ' Parabéns! Você atingiu ' || p_milestone_days || ' dias de sequência';
    END IF;
    
    -- Criar notificação usando função auxiliar
    PERFORM create_single_notification(
        p_user_id,
        NULL,  -- Notificação do sistema
        'streak_milestone',
        message_text,
        3  -- Alta prioridade
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', p_milestone_days, p_user_id, p_bonus_points;
END;
$function$;

-- Implementar sistema de notificação de nível
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🎉 IMPLEMENTANDO SISTEMA DE NOTIFICAÇÃO DE NÍVEL...';
END $$;

-- 3. HANDLE_LEVEL_UP_NOTIFICATION - Função para Mudanças de Nível
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

-- 4. Criar trigger para notificações de nível
CREATE TRIGGER level_up_notification_trigger 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_level_up_notification();

-- Verificação final
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ VERIFICAÇÃO FINAL...';
END $$;

-- Verificar se todas as funções foram criadas
SELECT 
    'FUNÇÕES CRIADAS:' as info,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_single_notification'
    ) THEN '✅ create_single_notification'
    ELSE '❌ create_single_notification' END as create_single,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'notify_streak_milestone_correct'
    ) THEN '✅ notify_streak_milestone_correct'
    ELSE '❌ notify_streak_milestone_correct' END as notify_streak,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'handle_level_up_notification'
    ) THEN '✅ handle_level_up_notification'
    ELSE '❌ handle_level_up_notification' END as level_function;

-- Verificar trigger
SELECT 
    'TRIGGER CRIADO:' as info,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'level_up_notification_trigger'
    ) THEN '✅ level_up_notification_trigger'
    ELSE '❌ level_up_notification_trigger' END as level_trigger;

-- Testar funções auxiliares
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 TESTANDO FUNÇÕES AUXILIARES...';
    
    -- Buscar um usuário para teste (se existir)
    SELECT id INTO test_user_id FROM public.profiles LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '📝 Testando create_single_notification...';
        PERFORM create_single_notification(
            test_user_id, 
            NULL, 
            'test', 
            'Teste de notificação - Migration 003 CORRIGIDA', 
            1
        );
        
        RAISE NOTICE '📝 Testando notify_streak_milestone_correct...';
        PERFORM notify_streak_milestone_correct(
            test_user_id, 
            7, 
            50
        );
        
        RAISE NOTICE '✅ Funções testadas com sucesso!';
        RAISE NOTICE '⚠️  Notificações de teste criadas - podem ser removidas se necessário';
    ELSE
        RAISE NOTICE '⚠️  Nenhum usuário encontrado para teste';
    END IF;
END $$;

-- Finalização
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 MIGRATION 003 CORRIGIDA CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 CORREÇÕES APLICADAS:';
    RAISE NOTICE '   ✅ create_single_notification() - Recriada';
    RAISE NOTICE '   ✅ notify_streak_milestone_correct() - Recriada';
    RAISE NOTICE '   ✅ handle_level_up_notification() - Criada';
    RAISE NOTICE '   ✅ level_up_notification_trigger - Criado';
    RAISE NOTICE '';
    RAISE NOTICE '🔔 NOTIFICAÇÕES AGORA FUNCIONAIS:';
    RAISE NOTICE '   🏆 Badges - Funcionarão automaticamente';
    RAISE NOTICE '   🔥 Streaks - Funcionarão automaticamente';
    RAISE NOTICE '   🎉 Níveis - Sistema implementado';
    RAISE NOTICE '';
    RAISE NOTICE '📱 PRÓXIMO PASSO: Testar todas as notificações';
END $$;

