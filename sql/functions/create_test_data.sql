-- ============================================================================
-- FUNÇÃO: create_test_data
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_test_data()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_1 UUID := '11111111-1111-1111-1111-111111111111';
    test_user_2 UUID := '22222222-2222-2222-2222-222222222222';
    test_post_id UUID;
    test_comment_id UUID;
    test_reaction_id UUID;
    test_feedback_id UUID;
BEGIN
    -- Limpar dados de teste anteriores
    DELETE FROM public.reactions WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.comments WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.feedbacks WHERE author_id IN (test_user_1, test_user_2) OR mentioned_user_id IN (test_user_1, test_user_2);
    DELETE FROM public.posts WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.points_history WHERE user_id IN (test_user_1, test_user_2);
    DELETE FROM public.user_points WHERE user_id IN (test_user_1, test_user_2);
    
    -- Criar post de teste
    INSERT INTO public.posts (id, user_id, celebrated_person_name, content, type, mentioned_user_id, created_at)
    VALUES (
        gen_random_uuid(), 
        test_user_1, 
        'Pessoa Teste', 
        'Post de teste para validação', 
        'gratitude', 
        test_user_2, 
        NOW()
    ) RETURNING id INTO test_post_id;
    
    -- Criar comentário de teste
    INSERT INTO public.comments (id, user_id, post_id, content, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_2,
        test_post_id,
        'Comentário de teste',
        NOW()
    ) RETURNING id INTO test_comment_id;
    
    -- Criar reação de teste
    INSERT INTO public.reactions (id, user_id, post_id, type, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_2,
        test_post_id,
        'like',
        NOW()
    ) RETURNING id INTO test_reaction_id;
    
    -- Criar feedback de teste
    INSERT INTO public.feedbacks (id, author_id, post_id, content, mentioned_user_id, created_at)
    VALUES (
        gen_random_uuid(),
        test_user_1,
        test_post_id,
        'Feedback de teste',
        test_user_2,
        NOW()
    ) RETURNING id INTO test_feedback_id;
    
    RETURN 'Dados de teste criados: Post=' || test_post_id || ', Comment=' || test_comment_id || ', Reaction=' || test_reaction_id || ', Feedback=' || test_feedback_id;
END;
$function$

