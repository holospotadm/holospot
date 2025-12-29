-- ============================================================================
-- FUNÇÃO: run_all_deletion_tests
-- ============================================================================

CREATE OR REPLACE FUNCTION public.run_all_deletion_tests()
 RETURNS TABLE(test_step text, result text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Passo 1: Criar dados de teste
    RETURN QUERY SELECT 'PASSO 1: Criar dados'::TEXT, create_test_data();
    
    -- Passo 2: Verificar pontos iniciais
    RETURN QUERY SELECT 'PASSO 2: Pontos iniciais'::TEXT, 
                        'User1: ' || COALESCE(up1.total_points::TEXT, '0') || 
                        ', User2: ' || COALESCE(up2.total_points::TEXT, '0')
    FROM (SELECT total_points FROM public.user_points WHERE user_id = '11111111-1111-1111-1111-111111111111') up1
    CROSS JOIN (SELECT total_points FROM public.user_points WHERE user_id = '22222222-2222-2222-2222-222222222222') up2;
    
    -- Passo 3: Testar deleção de reação
    RETURN QUERY SELECT 'PASSO 3: Deletar reação'::TEXT, test_reaction_deletion();
    
    -- Passo 4: Testar deleção de comentário
    RETURN QUERY SELECT 'PASSO 4: Deletar comentário'::TEXT, test_comment_deletion();
    
    -- Passo 5: Testar deleção de feedback
    RETURN QUERY SELECT 'PASSO 5: Deletar feedback'::TEXT, test_feedback_deletion();
    
    -- Passo 6: Verificar integridade final
    RETURN QUERY SELECT 'PASSO 6: Integridade final'::TEXT, 
                        CASE 
                            WHEN EXISTS (SELECT 1 FROM test_points_integrity()) 
                            THEN 'ERRO: Inconsistências encontradas'
                            ELSE 'OK: Pontos consistentes'
                        END;
END;
$function$

