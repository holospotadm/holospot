-- ============================================================================
-- FUNÇÃO: notify_badge_trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_badge_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Notificar badge conquistado
    PERFORM notify_badge_earned(
        NEW.user_id,
        NEW.badge_id,
        badge_info.name,
        badge_info.rarity
    );
    
    RETURN NEW;
END;
$function$

