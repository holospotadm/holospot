-- ============================================================================
-- FUNÇÃO: check_chain_participation_badges
-- ============================================================================

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
$function$

