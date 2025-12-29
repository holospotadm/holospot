-- ============================================================================
-- FUNÇÃO: migrate_existing_users_to_gamification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.migrate_existing_users_to_gamification()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user RECORD;
    v_migrated_count INTEGER := 0;
    v_posts_count INTEGER;
    v_reactions_count INTEGER;
    v_comments_count INTEGER;
    v_result JSON;
BEGIN
    -- Para cada usuário existente que NÃO tem pontos ainda
    FOR v_user IN 
        SELECT id FROM auth.users 
        WHERE id NOT IN (SELECT user_id FROM public.user_points WHERE user_id IS NOT NULL)
    LOOP
        -- Log do usuário sendo processado
        RAISE NOTICE 'Processando usuário: %', v_user.id;
        
        -- Inicializar pontos
        PERFORM initialize_user_points(v_user.id);
        
        -- Contar posts do usuário (CORRIGIDO: user_id ao invés de author_id)
        SELECT COUNT(*) INTO v_posts_count FROM public.posts WHERE user_id = v_user.id;
        
        -- Contar reações do usuário
        SELECT COUNT(*) INTO v_reactions_count FROM public.reactions WHERE user_id = v_user.id;
        
        -- Contar comentários do usuário
        SELECT COUNT(*) INTO v_comments_count FROM public.comments WHERE user_id = v_user.id;
        
        -- Log das estatísticas
        RAISE NOTICE 'Usuário %: % posts, % reações, % comentários', v_user.id, v_posts_count, v_reactions_count, v_comments_count;
        
        -- Adicionar pontos retroativos por posts (se houver)
        IF v_posts_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_posts', 
                v_posts_count * 10,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Adicionar pontos retroativos por reações (se houver)
        IF v_reactions_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_reactions', 
                v_reactions_count * 2,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Adicionar pontos retroativos por comentários (se houver)
        IF v_comments_count > 0 THEN
            PERFORM add_points_to_user(
                v_user.id, 
                'migration_comments', 
                v_comments_count * 5,
                NULL, 
                'migration'
            );
        END IF;
        
        -- Verificar badges
        PERFORM check_and_award_badges(v_user.id);
        
        v_migrated_count := v_migrated_count + 1;
    END LOOP;
    
    v_result := json_build_object(
        'success', true,
        'migrated_users', v_migrated_count,
        'message', 'Migração concluída com sucesso'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'migrated_users', v_migrated_count
    );
END;
$function$

