-- ============================================================================
-- FUNÇÃO: add_points_to_user
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_action_type text, p_points integer, p_reference_id uuid, p_reference_type text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Inserir no histórico de pontos com os novos campos
    INSERT INTO public.points_history (
        user_id,
        action_type,
        points_earned,
        reference_id,
        reference_type,
        post_id,
        reaction_type,
        reaction_user_id,
        created_at
    ) VALUES (
        p_user_id,
        p_action_type,
        p_points,
        p_reference_id,
        p_reference_type,
        p_post_id,
        p_reaction_type,
        p_reaction_user_id,
        NOW()
    );

    -- Atualizar total de pontos do usuário
    INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level, updated_at)
    VALUES (p_user_id, p_points, 1, GREATEST(0, 100 - p_points), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = user_points.total_points + p_points,
        updated_at = NOW();
END;
$function$

