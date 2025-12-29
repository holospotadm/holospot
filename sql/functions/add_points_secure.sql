-- ============================================================================
-- FUNÇÃO: add_points_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_points_secure(p_user_id uuid, p_points integer, p_action_type text, p_reference_id uuid, p_reference_type text, p_post_id uuid DEFAULT NULL::uuid, p_reaction_type text DEFAULT NULL::text, p_reaction_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Inserir pontos no histórico
    INSERT INTO public.points_history (
        user_id, points_earned, action_type, reference_id, reference_type, 
        post_id, reaction_type, reaction_user_id, created_at
    ) VALUES (
        p_user_id, p_points, p_action_type, p_reference_id, p_reference_type,
        p_post_id, p_reaction_type, p_reaction_user_id, NOW()
    );
    
    RAISE NOTICE 'Pontos adicionados: % pts para usuário % (ação: %)', p_points, p_user_id, p_action_type;
END;
$function$

