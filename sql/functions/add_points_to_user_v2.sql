-- ============================================================================
-- FUNÇÃO: add_points_to_user_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_points integer, p_action_type text, p_reference_id text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Inserir pontos no histórico
    INSERT INTO public.points_history (
        user_id,
        points_earned,
        action_type,
        reference_id,
        post_id,
        reaction_type,
        reaction_user_id,
        created_at
    ) VALUES (
        p_user_id,
        p_points,
        p_action_type,
        p_reference_id::uuid,  -- Cast TEXT para UUID
        p_post_id,
        p_reaction_type,
        p_reaction_user_id,
        NOW()
    );
    
    -- Atualizar total de pontos na tabela user_points (se existir)
    BEGIN
        INSERT INTO public.user_points (user_id, total_points, updated_at)
        VALUES (p_user_id, p_points, NOW())
        ON CONFLICT (user_id) 
        DO UPDATE SET 
            total_points = user_points.total_points + p_points,
            updated_at = NOW();
    EXCEPTION
        WHEN undefined_table THEN
            -- Tabela user_points não existe, ignorar
            NULL;
    END;
        
EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro
        RAISE NOTICE 'Erro ao adicionar pontos para usuário %: %', p_user_id, SQLERRM;
        -- Não falhar, apenas continuar
END;
$function$

