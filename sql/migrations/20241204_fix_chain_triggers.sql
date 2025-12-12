-- ============================================================================
-- FIX: Corrigir triggers de gamificação de correntes
-- ============================================================================
-- PROBLEMA: Triggers estão usando NEW.user_id quando deveria ser NEW.creator_id
-- ============================================================================

-- Recriar trigger de criação de corrente
CREATE OR REPLACE FUNCTION public.check_chain_creation_badges()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Adicionar pontos por criar corrente
    INSERT INTO points_history (user_id, action_type, points_earned, reference_type, reference_id)
    VALUES (NEW.creator_id, 'chain_created', 25, 'chain', NEW.id);
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.creator_id);
    
    -- Verificar badges
    PERFORM auto_badge_check_bonus(NEW.creator_id);
    
    RETURN NEW;
END;
$function$;

-- Comentário
COMMENT ON FUNCTION public.check_chain_creation_badges IS 'Adiciona pontos e verifica badges ao criar corrente (CORRIGIDO: usa creator_id)';

-- ✅ Trigger de criação corrigido
