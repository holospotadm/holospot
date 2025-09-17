-- ============================================================================
-- FUNÇÕES DE GAMIFICATION - EXTRAÍDO DO BANCO REAL
-- ============================================================================
-- Data de extração: 2025-09-17 02:21:37
-- Total de funções: 7
-- Fonte: Extração direta do Supabase
-- ============================================================================

-- FUNÇÃO: add_points_secure
-- ============================================================================

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
;

-- FUNÇÃO: add_points_to_user
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.add_points_to_user(p_user_id uuid, p_action_type character varying, p_points integer, p_reference_id uuid DEFAULT NULL::uuid, p_reference_type character varying DEFAULT NULL::character varying)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_current_points INTEGER;
    v_new_total_points INTEGER;
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_level_up BOOLEAN := false;
    v_result JSON;
BEGIN
    -- Inicializar pontos do usuário se não existir
    PERFORM initialize_user_points(p_user_id);
    
    -- Obter pontos atuais
    SELECT total_points, level_id INTO v_current_points, v_old_level
    FROM public.user_points 
    WHERE user_id = p_user_id;
    
    -- Calcular novos pontos
    v_new_total_points := v_current_points + p_points;
    
    -- Calcular novo nível
    v_new_level := calculate_user_level(v_new_total_points);
    
    -- Verificar se subiu de nível
    IF v_new_level > v_old_level THEN
        v_level_up := true;
    END IF;
    
    -- Atualizar pontos do usuário
    UPDATE public.user_points 
    SET 
        total_points = v_new_total_points,
        level_id = v_new_level,
        points_to_next_level = CASE 
            WHEN v_new_level < 10 THEN 
                (SELECT points_required FROM public.levels WHERE id = v_new_level + 1) - v_new_total_points
            ELSE 0
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Registrar no histórico
    INSERT INTO public.points_history (user_id, action_type, points_earned, reference_id, reference_type)
    VALUES (p_user_id, p_action_type, p_points, p_reference_id, p_reference_type);
    
    -- Verificar badges após adicionar pontos
    PERFORM check_and_award_badges(p_user_id);
    
    -- Retornar resultado
    v_result := json_build_object(
        'success', true,
        'points_added', p_points,
        'total_points', v_new_total_points,
        'old_level', v_old_level,
        'new_level', v_new_level,
        'level_up', v_level_up
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

-- FUNÇÃO: add_points_to_user
-- ============================================================================

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
;

-- FUNÇÃO: add_points_to_user
-- ============================================================================

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
;

-- FUNÇÃO: calculate_user_level
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.calculate_user_level(user_points integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_level INTEGER;
BEGIN
    SELECT id INTO user_level
    FROM public.levels
    WHERE points_required <= user_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    RETURN COALESCE(user_level, 1);
END;
$function$
;

-- FUNÇÃO: check_points_before_deletion
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_points_before_deletion()
 RETURNS TABLE(user_id uuid, points_history_count bigint, points_history_total bigint, user_points_total integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ph.user_id,
        COUNT(ph.id) as points_history_count,
        COALESCE(SUM(ph.points_earned), 0) as points_history_total,
        COALESCE(up.total_points, 0) as user_points_total
    FROM public.points_history ph
    LEFT JOIN public.user_points up ON ph.user_id = up.user_id
    WHERE ph.user_id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')
    GROUP BY ph.user_id, up.total_points
    ORDER BY ph.user_id;
END;
$function$
;

-- FUNÇÃO: delete_reaction_points_secure
-- ============================================================================

-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_reaction_points_secure(p_reaction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Deletar registros de pontos relacionados à reação
    DELETE FROM public.points_history 
    WHERE reference_id = p_reaction_id 
    AND reference_type = 'reaction';
    
    RAISE NOTICE 'Deletados registros de pontos para reação %', p_reaction_id;
END;
$function$
;

