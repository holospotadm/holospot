-- ============================================================================
-- FUNÇÃO: recalculate_user_retroactive_points
-- ============================================================================

CREATE OR REPLACE FUNCTION public.recalculate_user_retroactive_points(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_posts_count INTEGER := 0;
    v_reactions_count INTEGER := 0;
    v_comments_count INTEGER := 0;
    v_holofotes_count INTEGER := 0;
    v_total_retroactive_points INTEGER := 0;
    v_current_points INTEGER := 0;
    v_points_to_add INTEGER := 0;
    v_result JSON;
BEGIN
    -- Obter pontos atuais
    SELECT total_points INTO v_current_points
    FROM public.user_points
    WHERE user_id = p_user_id;
    
    -- Contar ações retroativas do usuário
    SELECT COUNT(*) INTO v_posts_count
    FROM public.posts
    WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_reactions_count
    FROM public.reactions
    WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_comments_count
    FROM public.comments
    WHERE user_id = p_user_id;
    
    SELECT COUNT(DISTINCT mentioned_user_id) INTO v_holofotes_count
    FROM public.posts
    WHERE user_id = p_user_id AND mentioned_user_id IS NOT NULL;
    
    -- Calcular total de pontos retroativos esperados
    v_total_retroactive_points := 
        (v_posts_count * 10) +           -- Posts: 10 pontos cada
        (v_reactions_count * 2) +        -- Reações: 2 pontos cada
        (v_comments_count * 5) +         -- Comentários: 5 pontos cada
        (v_holofotes_count * 20);        -- Holofotes: 20 pontos cada
    
    -- Calcular quantos pontos adicionar (descontar pontos já existentes)
    v_points_to_add := v_total_retroactive_points - v_current_points;
    
    -- Log das estatísticas
    RAISE NOTICE 'Usuário %: Posts=%, Reações=%, Comentários=%, Holofotes=%', 
        p_user_id, v_posts_count, v_reactions_count, v_comments_count, v_holofotes_count;
    RAISE NOTICE 'Pontos esperados=%, Pontos atuais=%, Pontos a adicionar=%', 
        v_total_retroactive_points, v_current_points, v_points_to_add;
    
    -- Se há pontos para adicionar, adicionar
    IF v_points_to_add > 0 THEN
        -- Adicionar pontos retroativos
        PERFORM add_points_to_user(
            p_user_id,
            'retroactive_calculation',
            v_points_to_add,
            NULL,
            'migration'
        );
        
        RAISE NOTICE 'Adicionados % pontos retroativos para usuário %', v_points_to_add, p_user_id;
    END IF;
    
    -- Retornar resultado
    v_result := json_build_object(
        'user_id', p_user_id,
        'posts_count', v_posts_count,
        'reactions_count', v_reactions_count,
        'comments_count', v_comments_count,
        'holofotes_count', v_holofotes_count,
        'total_retroactive_points', v_total_retroactive_points,
        'current_points_before', v_current_points,
        'points_added', v_points_to_add,
        'success', true
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'user_id', p_user_id
    );
END;
$function$

