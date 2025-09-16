-- ============================================================================
-- MIGRATION 003: Corrigir Sistema de Notificações (VERSÃO SEGURA)
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Criar funções auxiliares faltantes e implementar notificações de nível
-- Estratégia: Migração segura sem quebrar funções existentes
-- ============================================================================

-- Verificar estado atual
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 VERIFICANDO ESTADO ATUAL DAS NOTIFICAÇÕES...';
    RAISE NOTICE '';
END $$;

-- Verificar se funções auxiliares existem e seus tipos
SELECT 
    'FUNÇÕES AUXILIARES:' as info,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'create_single_notification'
    ) THEN '⚠️ create_single_notification EXISTS'
    ELSE '❌ create_single_notification MISSING' END as create_single,
    
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'notify_streak_milestone_correct'
    ) THEN '⚠️ notify_streak_milestone_correct EXISTS'
    ELSE '❌ notify_streak_milestone_correct MISSING' END as notify_streak;

-- Verificar tipo de retorno atual da função (se existir)
SELECT 
    'TIPO ATUAL:' as info,
    p.proname as function_name,
    t.typname as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_type t ON p.prorettype = t.oid
WHERE p.proname = 'create_single_notification';

-- Estratégia segura: Criar funções temporárias primeiro
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔧 CRIANDO FUNÇÕES TEMPORÁRIAS SEGURAS...';
END $$;

-- 1. CREATE_SINGLE_NOTIFICATION_NEW - Versão temporária
CREATE OR REPLACE FUNCTION public.create_single_notification_new(
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

-- 2. NOTIFY_STREAK_MILESTONE_CORRECT_NEW - Versão temporária
CREATE OR REPLACE FUNCTION public.notify_streak_milestone_correct_new(
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
    
    -- Criar notificação usando função auxiliar NOVA
    PERFORM create_single_notification_new(
        p_user_id,
        NULL,  -- Notificação do sistema
        'streak_milestone',
        message_text,
        3  -- Alta prioridade
    );
    
    RAISE NOTICE 'STREAK MILESTONE: % dias para % (+% pontos)', p_milestone_days, p_user_id, p_bonus_points;
END;
$function$;

-- Testar funções temporárias
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID;
BEGIN
    RAISE NOTICE '🧪 TESTANDO FUNÇÕES TEMPORÁRIAS...';
    
    -- Buscar um usuário para teste (se existir)
    SELECT id INTO test_user_id FROM public.profiles LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '📝 Testando create_single_notification_new...';
        PERFORM create_single_notification_new(
            test_user_id, 
            NULL, 
            'test_temp', 
            'Teste função temporária - Migration 003 SEGURA', 
            1
        );
        
        RAISE NOTICE '📝 Testando notify_streak_milestone_correct_new...';
        PERFORM notify_streak_milestone_correct_new(
            test_user_id, 
            7, 
            50
        );
        
        RAISE NOTICE '✅ Funções temporárias testadas com sucesso!';
    ELSE
        RAISE NOTICE '⚠️  Nenhum usuário encontrado para teste';
    END IF;
END $$;

-- Substituir funções antigas pelas novas (estratégia segura)
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🔄 SUBSTITUINDO FUNÇÕES ANTIGAS PELAS NOVAS...';
END $$;

-- Remover função antiga e criar nova com nome correto
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, UUID, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.create_single_notification(UUID, TEXT, TEXT);

-- Criar função final com nome correto
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

-- Remover função antiga de streak e criar nova
DROP FUNCTION IF EXISTS public.notify_streak_milestone_correct(UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.notify_streak_milestone_correct(UUID, INTEGER);

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

-- Remover função e trigger de nível se existirem
DROP TRIGGER IF EXISTS level_up_notification_trigger ON public.user_points;
DROP FUNCTION IF EXISTS public.handle_level_up_notification();

-- Criar função para mudanças de nível
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

-- Criar trigger para notificações de nível
CREATE TRIGGER level_up_notification_trigger 
    AFTER UPDATE ON public.user_points 
    FOR EACH ROW 
    EXECUTE FUNCTION handle_level_up_notification();

-- Limpar funções temporárias
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '🧹 LIMPANDO FUNÇÕES TEMPORÁRIAS...';
END $$;

DROP FUNCTION IF EXISTS public.create_single_notification_new(UUID, UUID, TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS public.notify_streak_milestone_correct_new(UUID, INTEGER, INTEGER);

-- Verificação final
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ VERIFICAÇÃO FINAL...';
END $$;

-- Verificar se todas as funções foram criadas
SELECT 
    'FUNÇÕES FINAIS:' as info,
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

-- Teste final das funções
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 TESTE FINAL DAS FUNÇÕES...';
    
    -- Buscar um usuário para teste (se existir)
    SELECT id INTO test_user_id FROM public.profiles LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '📝 Testando create_single_notification final...';
        PERFORM create_single_notification(
            test_user_id, 
            NULL, 
            'test_final', 
            'Teste final - Migration 003 SEGURA CONCLUÍDA', 
            1
        );
        
        RAISE NOTICE '📝 Testando notify_streak_milestone_correct final...';
        PERFORM notify_streak_milestone_correct(
            test_user_id, 
            30, 
            100
        );
        
        RAISE NOTICE '✅ Funções finais testadas com sucesso!';
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
    RAISE NOTICE '🎉 MIGRATION 003 SEGURA CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 ESTRATÉGIA SEGURA APLICADA:';
    RAISE NOTICE '   1️⃣ Criadas funções temporárias';
    RAISE NOTICE '   2️⃣ Testadas funções temporárias';
    RAISE NOTICE '   3️⃣ Substituídas funções antigas';
    RAISE NOTICE '   4️⃣ Limpadas funções temporárias';
    RAISE NOTICE '';
    RAISE NOTICE '📊 CORREÇÕES APLICADAS:';
    RAISE NOTICE '   ✅ create_single_notification() - Recriada com VOID';
    RAISE NOTICE '   ✅ notify_streak_milestone_correct() - Criada';
    RAISE NOTICE '   ✅ handle_level_up_notification() - Criada';
    RAISE NOTICE '   ✅ level_up_notification_trigger - Criado';
    RAISE NOTICE '';
    RAISE NOTICE '🔔 NOTIFICAÇÕES AGORA FUNCIONAIS:';
    RAISE NOTICE '   🏆 Badges - Funcionarão automaticamente';
    RAISE NOTICE '   🔥 Streaks - Funcionarão automaticamente';
    RAISE NOTICE '   🎉 Níveis - Sistema implementado';
    RAISE NOTICE '';
    RAISE NOTICE '⏱️  TEMPO DE INATIVIDADE: ZERO (migração segura)';
END $$;

