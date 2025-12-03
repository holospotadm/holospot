-- ============================================================================
-- MIGRATION: Fix Streak Bonus Points Crediting
-- ============================================================================
-- PROBLEMA:
-- - Notificação de milestone aparece corretamente
-- - Pontos bônus são inseridos no points_history
-- - MAS: Pontos não são creditados na tabela user_points
--
-- CAUSA:
-- - Função apply_streak_bonus_retroactive chama update_user_total_points
-- - MAS update_user_total_points NÃO tem SECURITY DEFINER
-- - Pode estar falhando silenciosamente por falta de permissões
--
-- SOLUÇÃO:
-- - Substituir update_user_total_points por recalculate_user_points_secure
-- - recalculate_user_points_secure tem SECURITY DEFINER e é mais confiável
-- ============================================================================

-- ============================================================================
-- RECRIAR FUNÇÃO apply_streak_bonus_retroactive COM CHAMADA CORRETA
-- ============================================================================

CREATE OR REPLACE FUNCTION public.apply_streak_bonus_retroactive(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_current_streak INTEGER;
    v_bonus_points INTEGER;
    v_milestone INTEGER;
BEGIN
    -- Buscar streak atual do usuário
    SELECT current_streak INTO v_current_streak
    FROM user_streaks 
    WHERE user_id = p_user_id;
    
    -- Se não tem streak, não aplicar bônus
    IF v_current_streak IS NULL OR v_current_streak < 7 THEN
        RETURN;
    END IF;
    
    -- Determinar milestone atingido
    CASE 
        WHEN v_current_streak >= 365 THEN v_milestone := 365;
        WHEN v_current_streak >= 182 THEN v_milestone := 182;
        WHEN v_current_streak >= 30 THEN v_milestone := 30;
        WHEN v_current_streak >= 7 THEN v_milestone := 7;
        ELSE RETURN; -- Não atingiu milestone
    END CASE;
    
    -- Calcular bônus usando função corrigida (agora recebe user_id)
    v_bonus_points := calculate_streak_bonus(p_user_id, v_milestone);
    
    -- Se bônus é 0, não aplicar
    IF v_bonus_points <= 0 THEN
        RETURN;
    END IF;
    
    -- Verificar se já foi aplicado este bônus
    IF NOT EXISTS (
        SELECT 1 FROM points_history 
        WHERE user_id = p_user_id 
        AND action_type = 'streak_bonus_retroactive'
        AND reference_type = 'milestone_' || v_milestone::text
    ) THEN
        -- Aplicar bônus retroativo
        INSERT INTO points_history (
            user_id, 
            points_earned, 
            action_type, 
            reference_id, 
            reference_type,
            created_at
        ) VALUES (
            p_user_id,
            v_bonus_points,
            'streak_bonus_retroactive',
            p_user_id,
            'milestone_' || v_milestone::text,
            NOW()
        );
        
        -- ✅ CORREÇÃO: Usar recalculate_user_points_secure ao invés de update_user_total_points
        -- Esta função tem SECURITY DEFINER e é mais confiável
        PERFORM recalculate_user_points_secure(p_user_id);
        
        RAISE NOTICE '✅ Bônus retroativo aplicado: User % - Streak % dias - Milestone % - Bônus % pontos', 
            p_user_id, v_current_streak, v_milestone, v_bonus_points;
    END IF;
END;
$function$;

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON FUNCTION public.apply_streak_bonus_retroactive(uuid) IS 
'Aplica bônus retroativo quando usuário atinge milestone de streak.
CORREÇÃO: Agora usa recalculate_user_points_secure para garantir que pontos sejam creditados.';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================

-- Verificar se função foi criada corretamente
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' 
        AND p.proname = 'apply_streak_bonus_retroactive'
    ) THEN
        RAISE NOTICE '✅ Função apply_streak_bonus_retroactive atualizada com sucesso';
    ELSE
        RAISE EXCEPTION '❌ Erro: Função apply_streak_bonus_retroactive não foi criada';
    END IF;
END $$;

-- ============================================================================
-- FIM DA MIGRATION
-- ============================================================================
