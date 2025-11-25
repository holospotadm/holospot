-- ============================================================================
-- FUNÇÃO: Recalcular streak de TODOS os usuários
-- ============================================================================
-- Data: 2025-11-12
-- Uso: Executar UMA VEZ após implementar a nova lógica incremental
-- Objetivo: Garantir que todos os streaks estejam corretos
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_all_users_streaks()
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    old_streak INTEGER,
    new_streak INTEGER,
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_user RECORD;
    v_old_streak INTEGER;
    v_new_streak INTEGER;
    v_total_users INTEGER := 0;
    v_processed_users INTEGER := 0;
    v_start_time TIMESTAMP;
BEGIN
    v_start_time := NOW();
    
    -- Contar total de usuários
    SELECT COUNT(*) INTO v_total_users FROM profiles;
    
    RAISE NOTICE '🔄 Iniciando recálculo de streaks para % usuários...', v_total_users;
    
    -- Loop por todos os usuários
    FOR v_user IN 
        SELECT p.id, p.username 
        FROM profiles p
        ORDER BY p.id
    LOOP
        v_processed_users := v_processed_users + 1;
        
        -- Buscar streak antigo (se existir)
        SELECT current_streak INTO v_old_streak
        FROM user_streaks
        WHERE user_streaks.user_id = v_user.id;
        
        IF v_old_streak IS NULL THEN
            v_old_streak := 0;
        END IF;
        
        -- Recalcular do zero
        BEGIN
            PERFORM recalculate_user_streak_from_scratch(v_user.id);
            
            -- Buscar novo streak
            SELECT current_streak INTO v_new_streak
            FROM user_streaks
            WHERE user_streaks.user_id = v_user.id;
            
            IF v_new_streak IS NULL THEN
                v_new_streak := 0;
            END IF;
            
            -- Log de progresso a cada 10 usuários
            IF v_processed_users % 10 = 0 THEN
                RAISE NOTICE '📊 Progresso: %/% usuários processados (%.1f%%)', 
                    v_processed_users, v_total_users, 
                    (v_processed_users::FLOAT / v_total_users::FLOAT * 100);
            END IF;
            
            -- Retornar resultado
            RETURN QUERY SELECT 
                v_user.id,
                v_user.username,
                v_old_streak,
                v_new_streak,
                CASE 
                    WHEN v_old_streak = v_new_streak THEN '✅ Sem mudança'
                    WHEN v_old_streak < v_new_streak THEN '📈 Aumentou'
                    ELSE '📉 Diminuiu'
                END::TEXT;
                
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erro ao processar usuário %: %', v_user.username, SQLERRM;
            
            RETURN QUERY SELECT 
                v_user.id,
                v_user.username,
                v_old_streak,
                0::INTEGER,
                ('❌ Erro: ' || SQLERRM)::TEXT;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Recálculo completo! % usuários processados em %', 
        v_processed_users, 
        (NOW() - v_start_time);
END;
$$;

GRANT EXECUTE ON FUNCTION public.recalculate_all_users_streaks() TO authenticated;

-- ============================================================================
-- FUNÇÃO AUXILIAR: Estatísticas de streaks
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_streak_statistics()
RETURNS TABLE (
    total_users INTEGER,
    users_with_streak INTEGER,
    avg_streak NUMERIC,
    max_streak INTEGER,
    users_at_milestone_7 INTEGER,
    users_at_milestone_30 INTEGER,
    users_at_milestone_182 INTEGER,
    users_at_milestone_365 INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM profiles) as total_users,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak > 0) as users_with_streak,
        (SELECT ROUND(AVG(current_streak), 2) FROM user_streaks WHERE current_streak > 0) as avg_streak,
        (SELECT MAX(current_streak)::INTEGER FROM user_streaks) as max_streak,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 7) as users_at_milestone_7,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 30) as users_at_milestone_30,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 182) as users_at_milestone_182,
        (SELECT COUNT(*)::INTEGER FROM user_streaks WHERE current_streak >= 365) as users_at_milestone_365;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_streak_statistics() TO authenticated;

-- ============================================================================
-- INSTRUÇÕES DE USO
-- ============================================================================

-- 1. VER ESTATÍSTICAS ANTES:
-- SELECT * FROM get_streak_statistics();

-- 2. RECALCULAR TODOS OS STREAKS (pode demorar alguns minutos):
-- SELECT * FROM recalculate_all_users_streaks();

-- 3. VER ESTATÍSTICAS DEPOIS:
-- SELECT * FROM get_streak_statistics();

-- 4. VER USUÁRIOS COM MUDANÇAS SIGNIFICATIVAS:
-- SELECT * FROM recalculate_all_users_streaks() 
-- WHERE old_streak != new_streak
-- ORDER BY ABS(new_streak - old_streak) DESC;

-- ============================================================================
-- EXEMPLO DE SAÍDA
-- ============================================================================
-- user_id                              | username      | old_streak | new_streak | status
-- -------------------------------------|---------------|------------|------------|------------------
-- e1eda873-5c70-49c1-b141-91e6e3928edf | guiidutra     | 0          | 7          | 📈 Aumentou
-- bb90f878-c0d9-4222-8e7c-60be2683e8e1 | guilherme     | 6          | 6          | ✅ Sem mudança
-- ============================================================================

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 1. Esta função pode demorar alguns minutos para muitos usuários
-- 2. Execute APENAS UMA VEZ após implementar a nova lógica incremental
-- 3. Após executar, a lógica incremental manterá os streaks corretos
-- 4. Use get_streak_statistics() para ver um resumo geral
-- ============================================================================
