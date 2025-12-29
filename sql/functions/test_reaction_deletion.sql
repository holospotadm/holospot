-- ============================================================================
-- FUNÇÃO: test_reaction_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_reaction_deletion()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    reaction_to_delete UUID;
    points_before INTEGER;
    points_after INTEGER;
    history_count_before BIGINT;
    history_count_after BIGINT;
BEGIN
    -- Buscar uma reação para deletar
    SELECT id INTO reaction_to_delete 
    FROM public.reactions 
    WHERE user_id = test_user_2 
    LIMIT 1;
    
    IF reaction_to_delete IS NULL THEN
        RETURN 'ERRO: Nenhuma reação encontrada para teste';
    END IF;
    
    -- Verificar pontos antes
    SELECT COALESCE(total_points, 0) INTO points_before
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_before
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    -- Deletar reação
    DELETE FROM public.reactions WHERE id = reaction_to_delete;
    
    -- Verificar pontos depois
    SELECT COALESCE(total_points, 0) INTO points_after
    FROM public.user_points 
    WHERE user_id = test_user_2;
    
    SELECT COUNT(*) INTO history_count_after
    FROM public.points_history 
    WHERE user_id = test_user_2;
    
    RETURN 'TESTE REAÇÃO: Pontos antes=' || points_before || ', depois=' || points_after || 
           ', Histórico antes=' || history_count_before || ', depois=' || history_count_after ||
           ', Diferença pontos=' || (points_before - points_after) ||
           ', Diferença histórico=' || (history_count_before - history_count_after);
END;
$function$

