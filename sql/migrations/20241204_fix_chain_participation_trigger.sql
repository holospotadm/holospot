-- ============================================================================
-- FIX: Corrigir trigger check_chain_participation_badges
-- ============================================================================
-- PROBLEMA: Trigger usa NEW.user_id mas chain_posts tem NEW.author_id
-- SOLUÇÃO: Corrigir para usar NEW.author_id
-- ============================================================================

-- Remover trigger antigo
DROP TRIGGER IF EXISTS trigger_check_chain_participation_badges ON chain_posts;

-- Recriar função corrigida
CREATE OR REPLACE FUNCTION public.check_chain_participation_badges()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Adicionar pontos por participar de corrente
    INSERT INTO points_history (user_id, action_type, points_earned, reference_type, reference_id)
    VALUES (NEW.author_id, 'chain_participated', 15, 'chain', NEW.chain_id);  -- CORRIGIDO: NEW.user_id → NEW.author_id
    
    -- Recalcular pontos
    PERFORM recalculate_user_points_secure(NEW.author_id);  -- CORRIGIDO: NEW.user_id → NEW.author_id
    
    -- Verificar badges
    PERFORM auto_badge_check_bonus(NEW.author_id);  -- CORRIGIDO: NEW.user_id → NEW.author_id
    
    RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.check_chain_participation_badges IS 'Trigger para adicionar pontos e verificar badges ao participar de corrente (CORRIGIDO: usa NEW.author_id)';

-- Recriar trigger
CREATE TRIGGER trigger_check_chain_participation_badges
    AFTER INSERT ON chain_posts
    FOR EACH ROW
    EXECUTE FUNCTION check_chain_participation_badges();

-- ✅ Trigger corrigido
