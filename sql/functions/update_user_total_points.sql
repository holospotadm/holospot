-- ============================================================================
-- FUNÇÃO: update_user_total_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_total_points(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_total INTEGER;
    new_level_id INTEGER;
    old_level_id INTEGER;
    level_changed BOOLEAN := FALSE;
BEGIN
    -- 1. Calcular novo total de pontos
    SELECT COALESCE(SUM(points_earned), 0) INTO new_total
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- 2. Calcular nível correto baseado nos pontos
    SELECT id INTO new_level_id
    FROM public.levels 
    WHERE new_total >= min_points
    ORDER BY min_points DESC
    LIMIT 1;
    
    -- Se não encontrou nível, usar nível 1
    IF new_level_id IS NULL THEN
        SELECT id INTO new_level_id 
        FROM public.levels 
        ORDER BY id ASC 
        LIMIT 1;
        
        -- Fallback absoluto se não há níveis
        IF new_level_id IS NULL THEN
            new_level_id := 1;
        END IF;
    END IF;
    
    -- 3. Buscar nível atual do usuário (se existir)
    SELECT level_id INTO old_level_id
    FROM public.user_points 
    WHERE user_id = p_user_id;
    
    -- 4. Verificar se nível mudou
    IF old_level_id IS DISTINCT FROM new_level_id THEN
        level_changed := TRUE;
    END IF;
    
    -- 5. Verificar se coluna level_id existe na tabela
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_points' 
        AND column_name = 'level_id'
    ) THEN
        -- Atualizar COM level_id (se coluna existir)
        INSERT INTO public.user_points (user_id, total_points, level_id, updated_at)
        VALUES (p_user_id, new_total, new_level_id, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = EXCLUDED.total_points,
            level_id = EXCLUDED.level_id,
            updated_at = EXCLUDED.updated_at;
    ELSE
        -- Atualizar SEM level_id (se coluna não existir)
        INSERT INTO public.user_points (user_id, total_points, updated_at)
        VALUES (p_user_id, new_total, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = EXCLUDED.total_points,
            updated_at = EXCLUDED.updated_at;
            
        RAISE NOTICE '⚠️ AVISO: Coluna level_id não existe na tabela user_points!';
    END IF;
    
    -- 6. Log para debug
    IF level_changed THEN
        RAISE NOTICE '🎉 LEVEL UP! Usuário % - Level %→% - % pontos', 
            p_user_id, old_level_id, new_level_id, new_total;
    ELSE
        RAISE NOTICE '✅ Pontos atualizados para usuário %: % pontos (level calculado: %)', 
            p_user_id, new_total, new_level_id;
    END IF;
END;
$function$

