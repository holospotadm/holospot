-- ============================================================================
-- FUNÇÃO: test_feedback_deletion
-- ============================================================================

CREATE OR REPLACE FUNCTION public.test_feedback_deletion()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_1 UUID := '11111111-1111-1111-1111-111111111111';
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    feedback_to_delete UUID;
    points_before_1 INTEGER;
    points_after_1 INTEGER;
    points_before_2 INTEGER;
    points_after_2 INTEGER;
BEGIN
    -- Buscar um feedback para deletar
    SELECT id INTO feedback_to_delete 
    FROM public.feedbacks 
    WHERE author_id = test_user_1 
    LIMIT 1;
    
    IF feedback_to_delete IS NULL THEN
        RETURN 'ERRO: Nenhum feedback encontrado para teste';
    END IF;
    
    -- Verificar pontos antes (ambos usuários)
    SELECT COALESCE(total_points, 0) INTO points_before_1
    FROM public.user_points WHERE user_id = test_user_1;
    
    SELECT COALESCE(total_points, 0) INTO points_before_2
    FROM public.user_points WHERE user_id = test_user_2;
    
    -- Deletar feedback
    DELETE FROM public.feedbacks WHERE id = feedback_to_delete;
    
    -- Verificar pontos depois
    SELECT COALESCE(total_points, 0) INTO points_after_1
    FROM public.user_points WHERE user_id = test_user_1;
    
    SELECT COALESCE(total_points, 0) INTO points_after_2
    FROM public.user_points WHERE user_id = test_user_2;
    
    RETURN 'TESTE FEEDBACK: User1 antes=' || points_before_1 || ', depois=' || points_after_1 || 
           ' (diff=' || (points_before_1 - points_after_1) || '), ' ||
           'User2 antes=' || points_before_2 || ', depois=' || points_after_2 || 
           ' (diff=' || (points_before_2 - points_after_2) || ')';
END;
$function$

