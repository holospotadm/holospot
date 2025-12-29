-- ============================================================================
-- FUNÇÃO: handle_badge_notification_definitive
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_badge_notification_definitive()
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
    PERFORM notify_badge_earned_definitive(
        NEW.user_id,
        NEW.badge_id,
        badge_info.name,
        badge_info.rarity
    );
    
    RAISE NOTICE 'Badge conquistado: % por %', badge_info.name, NEW.user_id;
    
    RETURN NEW;
END;
$function$

