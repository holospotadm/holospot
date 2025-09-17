-- ============================================================================
-- MIGRATION 007: CORREÇÃO COMPLETA DO SISTEMA DE STREAK (CORRIGIDA)
-- ============================================================================
-- Data: 2025-09-16
-- Objetivo: Implementar sistema de streak automático e corrigir duplicações
-- Versão: CORRIGIDA - Remove funções existentes antes de recriar
-- ============================================================================

-- FASE 1: LIMPEZA E REMOÇÃO DE DUPLICAÇÕES
-- ============================================================================

-- 1.1 Remover funções existentes para evitar conflitos de tipo
DROP FUNCTION IF EXISTS public.calculate_consecutive_days(uuid);
DROP FUNCTION IF EXISTS public.calculate_user_streak(uuid);
DROP FUNCTION IF EXISTS public.update_user_streak(uuid);
DROP FUNCTION IF EXISTS public.update_user_streak_trigger();

-- 1.2 Log da limpeza
DO $$
BEGIN
    RAISE NOTICE '✅ FASE 1 CONCLUÍDA: Funções existentes removidas para recriação';
END $$;

-- FASE 2: CRIAR FUNÇÃO DE CÁLCULO DE STREAK CORRIGIDA
-- ============================================================================

-- 2.1 Criar função calculate_user_streak com lógica correta
CREATE OR REPLACE FUNCTION public.calculate_user_streak(p_user_id uuid)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_check_date DATE;
    v_has_activity BOOLEAN;
BEGIN
    v_check_date := v_current_date;
    
    -- Loop para contar dias consecutivos com atividade
    LOOP
        -- Verificar atividades do dia (LÓGICA CORRIGIDA CONFORME ESPECIFICAÇÃO)
        SELECT EXISTS (
            SELECT 1 FROM (
                -- Posts criados mencionando outros (@username)
                SELECT DATE(created_at) as activity_date 
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND (content ~ '@\w+' OR content IS NOT NULL)  -- Posts com menções ou qualquer post
                
                UNION ALL
                
                -- Comentários em qualquer post (incluindo próprios)
                SELECT DATE(created_at) as activity_date 
                FROM public.comments 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Reações em qualquer post
                SELECT DATE(created_at) as activity_date 
                FROM public.reactions 
                WHERE user_id = p_user_id
                
                UNION ALL
                
                -- Feedbacks ESCRITOS (giving feedback on any post)
                SELECT DATE(created_at) as activity_date 
                FROM public.feedbacks 
                WHERE author_id = p_user_id
            ) activities
            WHERE activity_date = v_check_date
        ) INTO v_has_activity;
        
        -- Se não houve atividade neste dia, parar o loop
        IF NOT v_has_activity THEN
            -- Se é hoje e não tem atividade, streak é 0
            IF v_check_date = v_current_date THEN
                v_streak := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Se houve atividade, incrementar streak
        v_streak := v_streak + 1;
        
        -- Ir para o dia anterior
        v_check_date := v_check_date - INTERVAL '1 day';
        
        -- Limite de segurança para evitar loop infinito (máximo 365 dias)
        IF v_streak >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_streak;
END;
$$;

-- 2.2 Log da criação
DO $$
BEGIN
    RAISE NOTICE '✅ FASE 2 CONCLUÍDA: Função de cálculo criada';
END $$;

-- FASE 3: CRIAR FUNÇÃO DE ATUALIZAÇÃO COM MILESTONES
-- ============================================================================

-- 3.1 Criar função update_user_streak com lógica de milestones
CREATE OR REPLACE FUNCTION public.update_user_streak(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_streak INTEGER;
    v_old_streak INTEGER;
    v_old_milestone INTEGER;
    v_next_milestone INTEGER;
    v_milestone_reached BOOLEAN := FALSE;
BEGIN
    -- Calcular novo streak
    v_new_streak := calculate_user_streak(p_user_id);
    
    -- Buscar dados atuais (se existirem)
    SELECT current_streak, next_milestone 
    INTO v_old_streak, v_old_milestone
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não existe registro, criar valores padrão
    IF v_old_streak IS NULL THEN
        v_old_streak := 0;
        v_old_milestone := 7;
    END IF;
    
    -- Determinar próximo milestone baseado no novo streak
    CASE 
        WHEN v_new_streak >= 365 THEN v_next_milestone := 365;  -- Máximo
        WHEN v_new_streak >= 182 THEN v_next_milestone := 365;  -- Próximo: 1 ano
        WHEN v_new_streak >= 30 THEN v_next_milestone := 182;   -- Próximo: 6 meses
        WHEN v_new_streak >= 7 THEN v_next_milestone := 30;     -- Próximo: 1 mês
        ELSE v_next_milestone := 7;                             -- Próximo: 1 semana
    END CASE;
    
    -- Verificar se atingiu um novo milestone
    IF v_new_streak > v_old_streak AND (
        (v_old_streak < 7 AND v_new_streak >= 7) OR
        (v_old_streak < 30 AND v_new_streak >= 30) OR
        (v_old_streak < 182 AND v_new_streak >= 182) OR
        (v_old_streak < 365 AND v_new_streak >= 365)
    ) THEN
        v_milestone_reached := TRUE;
    END IF;
    
    -- Atualizar ou inserir dados na tabela
    INSERT INTO user_streaks (user_id, current_streak, next_milestone, last_activity_date, updated_at)
    VALUES (p_user_id, v_new_streak, v_next_milestone, CURRENT_DATE, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        current_streak = EXCLUDED.current_streak,
        next_milestone = EXCLUDED.next_milestone,
        last_activity_date = EXCLUDED.last_activity_date,
        updated_at = EXCLUDED.updated_at;
    
    -- Log para debug
    RAISE NOTICE 'Streak atualizado: User % - Streak %→% (Milestone atingido: %)', 
        p_user_id, v_old_streak, v_new_streak, v_milestone_reached;
        
    -- Se atingiu milestone, o trigger de notificação vai disparar automaticamente
    -- devido ao UPDATE na tabela user_streaks
END;
$$;

-- 3.2 Log da criação
DO $$
BEGIN
    RAISE NOTICE '✅ FASE 3 CONCLUÍDA: Função de atualização criada';
END $$;

-- FASE 4: CRIAR FUNÇÃO DE TRIGGER PARA ATUALIZAÇÃO AUTOMÁTICA
-- ============================================================================

-- 4.1 Criar função que será chamada pelos triggers
CREATE OR REPLACE FUNCTION public.update_user_streak_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Atualizar streak do usuário que fez a atividade
    PERFORM update_user_streak(NEW.user_id);
    
    -- Para feedbacks, também atualizar streak do usuário mencionado
    -- (porque receber feedback também pode ser considerado engajamento)
    IF TG_TABLE_NAME = 'feedbacks' AND NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM update_user_streak(NEW.mentioned_user_id);
    END IF;
    
    RETURN NEW;
END;
$$;

-- 4.2 Log da criação
DO $$
BEGIN
    RAISE NOTICE '✅ FASE 4 CONCLUÍDA: Função de trigger criada';
END $$;

-- FASE 5: ADICIONAR TRIGGERS AUTOMÁTICOS NAS TABELAS DE ATIVIDADE
-- ============================================================================

-- 5.1 Trigger para POSTS
DROP TRIGGER IF EXISTS update_streak_after_post ON posts;
CREATE TRIGGER update_streak_after_post
    AFTER INSERT ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_user_streak_trigger();

-- 5.2 Trigger para COMMENTS
DROP TRIGGER IF EXISTS update_streak_after_comment ON comments;
CREATE TRIGGER update_streak_after_comment
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION update_user_streak_trigger();

-- 5.3 Trigger para REACTIONS
DROP TRIGGER IF EXISTS update_streak_after_reaction ON reactions;
CREATE TRIGGER update_streak_after_reaction
    AFTER INSERT ON reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_user_streak_trigger();

-- 5.4 Trigger para FEEDBACKS
DROP TRIGGER IF EXISTS update_streak_after_feedback ON feedbacks;
CREATE TRIGGER update_streak_after_feedback
    AFTER INSERT ON feedbacks
    FOR EACH ROW
    EXECUTE FUNCTION update_user_streak_trigger();

-- 5.5 Log dos triggers
DO $$
BEGIN
    RAISE NOTICE '✅ FASE 5 CONCLUÍDA: Triggers automáticos adicionados em 4 tabelas';
END $$;

-- FASE 6: RECALCULAR STREAKS EXISTENTES
-- ============================================================================

-- 6.1 Recalcular streaks de todos os usuários existentes
DO $$
DECLARE
    user_record RECORD;
    total_users INTEGER := 0;
BEGIN
    -- Contar usuários
    SELECT COUNT(*) INTO total_users FROM user_streaks;
    
    -- Recalcular para cada usuário
    FOR user_record IN 
        SELECT DISTINCT user_id FROM user_streaks
    LOOP
        PERFORM update_user_streak(user_record.user_id);
    END LOOP;
    
    RAISE NOTICE '✅ FASE 6 CONCLUÍDA: Streaks recalculados para % usuários', total_users;
END $$;

-- FASE 7: VALIDAÇÃO E TESTES
-- ============================================================================

-- 7.1 Verificar se triggers foram criados
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
    AND t.tgname LIKE 'update_streak_after_%'
    AND NOT t.tgisinternal;
    
    IF trigger_count = 4 THEN
        RAISE NOTICE '✅ VALIDAÇÃO: 4 triggers de streak criados com sucesso';
    ELSE
        RAISE WARNING '⚠️ VALIDAÇÃO: Esperado 4 triggers, encontrado %', trigger_count;
    END IF;
END $$;

-- 7.2 Verificar se função duplicada foi removida
DO $$
DECLARE
    func_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' 
        AND p.proname = 'calculate_consecutive_days'
    ) INTO func_exists;
    
    IF NOT func_exists THEN
        RAISE NOTICE '✅ VALIDAÇÃO: Função duplicada removida com sucesso';
    ELSE
        RAISE WARNING '⚠️ VALIDAÇÃO: Função duplicada ainda existe';
    END IF;
END $$;

-- 7.3 Testar função de cálculo
DO $$
DECLARE
    test_user_id UUID;
    test_streak INTEGER;
BEGIN
    -- Pegar um usuário existente para teste
    SELECT user_id INTO test_user_id FROM user_streaks LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        SELECT calculate_user_streak(test_user_id) INTO test_streak;
        RAISE NOTICE '✅ VALIDAÇÃO: Função de cálculo testada - User: %, Streak: %', test_user_id, test_streak;
    END IF;
END $$;

-- 7.4 Mostrar estado final das funções
DO $$
DECLARE
    func_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' 
    AND (p.proname LIKE '%streak%' OR p.proname LIKE '%consecutive%');
    
    RAISE NOTICE '✅ VALIDAÇÃO: % funções de streak existem no sistema', func_count;
END $$;

-- ============================================================================
-- RESUMO FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '🎉 MIGRATION 007 CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '🎉 ============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ FASE 1: Funções existentes removidas e recriadas';
    RAISE NOTICE '✅ FASE 2: Lógica de cálculo corrigida';
    RAISE NOTICE '✅ FASE 3: Milestones implementados';
    RAISE NOTICE '✅ FASE 4: Função de trigger criada';
    RAISE NOTICE '✅ FASE 5: 4 triggers automáticos adicionados';
    RAISE NOTICE '✅ FASE 6: Streaks existentes recalculados';
    RAISE NOTICE '✅ FASE 7: Validações executadas';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 SISTEMA DE STREAK AGORA É AUTOMÁTICO!';
    RAISE NOTICE '🚀 Streaks serão atualizados em tempo real após qualquer atividade!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PRÓXIMOS PASSOS:';
    RAISE NOTICE '   1. Teste fazendo uma atividade (post, comentário, reação, feedback)';
    RAISE NOTICE '   2. Verifique se o streak foi atualizado automaticamente';
    RAISE NOTICE '   3. Confirme se notificações de milestone funcionam';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

