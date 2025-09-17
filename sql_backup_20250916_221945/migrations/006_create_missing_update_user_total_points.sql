-- ============================================================================
-- MIGRATION 006: CRIAR FUNÇÃO update_user_total_points AUSENTE
-- ============================================================================
-- Solução definitiva para notificações de level-up
-- Esta função estava sendo chamada mas não existia!
-- ============================================================================

-- 1. VERIFICAR SE FUNÇÃO JÁ EXISTE
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_user_total_points'
    ) THEN
        RAISE NOTICE '⚠️ Função update_user_total_points já existe - será recriada';
        DROP FUNCTION IF EXISTS public.update_user_total_points(UUID);
    ELSE
        RAISE NOTICE '❌ Função update_user_total_points não existe - criando...';
    END IF;
END $$;

-- 2. CRIAR FUNÇÃO update_user_total_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_total_points(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
AS $function$
DECLARE
    total_points_calculated INTEGER;
    current_level_id INTEGER;
    new_level_id INTEGER;
    old_level_id INTEGER;
    level_changed BOOLEAN := FALSE;
BEGIN
    -- 1. Calcular total de pontos do histórico
    SELECT COALESCE(SUM(points_earned), 0) 
    INTO total_points_calculated
    FROM points_history 
    WHERE user_id = p_user_id;
    
    RAISE NOTICE 'CALCULATING POINTS: User % has % total points', p_user_id, total_points_calculated;
    
    -- 2. Determinar nível correto baseado nos pontos
    SELECT id INTO new_level_id
    FROM levels 
    WHERE total_points_calculated >= min_points
    ORDER BY min_points DESC
    LIMIT 1;
    
    -- Se não encontrou nível, usar nível 1
    IF new_level_id IS NULL THEN
        SELECT id INTO new_level_id FROM levels ORDER BY id ASC LIMIT 1;
        IF new_level_id IS NULL THEN
            new_level_id := 1; -- Fallback absoluto
        END IF;
    END IF;
    
    RAISE NOTICE 'LEVEL CALCULATED: User % should be level %', p_user_id, new_level_id;
    
    -- 3. Buscar nível atual do usuário
    SELECT level_id INTO old_level_id
    FROM user_points 
    WHERE user_id = p_user_id;
    
    -- 4. Verificar se nível mudou
    IF old_level_id IS DISTINCT FROM new_level_id THEN
        level_changed := TRUE;
        RAISE NOTICE 'LEVEL CHANGE: User % - %→%', p_user_id, old_level_id, new_level_id;
    END IF;
    
    -- 5. Atualizar ou inserir na tabela user_points
    INSERT INTO user_points (
        user_id, 
        total_points, 
        level_id,
        current_level,
        created_at, 
        updated_at
    ) VALUES (
        p_user_id, 
        total_points_calculated, 
        new_level_id,
        new_level_id,
        NOW(), 
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_points = total_points_calculated,
        level_id = new_level_id,
        current_level = new_level_id,
        updated_at = NOW();
    
    -- 6. Log final
    IF level_changed THEN
        RAISE NOTICE '🎉 LEVEL UP! User % advanced to level %', p_user_id, new_level_id;
    ELSE
        RAISE NOTICE '✅ POINTS UPDATED: User % - % points, level %', p_user_id, total_points_calculated, new_level_id;
    END IF;
        
END;
$function$;

-- 3. COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.update_user_total_points(UUID) IS 
'Atualiza total de pontos e nível do usuário baseado no histórico.
CRÍTICO: Esta função dispara o trigger de level-up quando nível muda.
Chamada por: handle_post_insert_secure, handle_comment_insert_secure, etc.';

-- 4. TESTE DA FUNÇÃO
-- ============================================================================

DO $$
DECLARE
    test_user_id UUID;
    points_before INTEGER;
    level_before INTEGER;
    points_after INTEGER;
    level_after INTEGER;
BEGIN
    -- Buscar usuário para teste
    SELECT user_id, total_points, level_id 
    INTO test_user_id, points_before, level_before
    FROM user_points 
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'TESTE CANCELADO: Nenhum usuário encontrado';
        RETURN;
    END IF;
    
    RAISE NOTICE 'TESTE INICIADO: User % - Points: %, Level: %', 
        test_user_id, points_before, level_before;
    
    -- Executar função
    PERFORM update_user_total_points(test_user_id);
    
    -- Verificar resultado
    SELECT total_points, level_id 
    INTO points_after, level_after
    FROM user_points 
    WHERE user_id = test_user_id;
    
    RAISE NOTICE 'TESTE CONCLUÍDO: User % - Points: %→%, Level: %→%', 
        test_user_id, points_before, points_after, level_before, level_after;
        
END $$;

-- 5. VERIFICAÇÃO FINAL
-- ============================================================================

SELECT 
    'FUNÇÃO CRIADA' as status,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_user_total_points') 
         THEN '✅ update_user_total_points EXISTS' 
         ELSE '❌ update_user_total_points MISSING' END as function_status;

-- 6. INSTRUÇÕES DE USO
-- ============================================================================

/*
COMO TESTAR:

1. Execute esta migration no Supabase
2. Faça uma ação que gere pontos (criar post, comentário, etc.)
3. Verifique se level_id foi atualizado:
   SELECT user_id, total_points, level_id FROM user_points WHERE user_id = 'seu-id';
4. Verifique se notificação foi criada:
   SELECT * FROM notifications WHERE type = 'level_up' ORDER BY created_at DESC;

LOGS ESPERADOS:
- CALCULATING POINTS: User xxx has yyy total points
- LEVEL CALCULATED: User xxx should be level yyy
- LEVEL CHANGE: User xxx - old→new (se mudou)
- 🎉 LEVEL UP! User xxx advanced to level yyy (se mudou)

Se não aparecer logs, a função não está sendo chamada.
Se aparecer logs mas level_id não mudar, há problema na lógica.
Se level_id mudar mas notificação não aparecer, problema no trigger.
*/

