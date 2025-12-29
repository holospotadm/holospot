-- ============================================================================
-- FUNÇÃO: handle_badge_notification_only
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_badge_notification_only()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    badge_info RECORD;
    message_text TEXT;
BEGIN
    -- Buscar informações do badge
    SELECT name, rarity INTO badge_info
    FROM public.badges 
    WHERE id = NEW.badge_id;
    
    -- Montar mensagem
    message_text := '🏆 Parabéns! Você conquistou o emblema "' || badge_info.name || '" (' || badge_info.rarity || ')';
    
    -- Criar APENAS notificação (pontos já são tratados por outros triggers)
    PERFORM create_single_notification(
        NEW.user_id, NULL, 'badge_earned', message_text, 3
    );
    
    RAISE NOTICE 'BADGE NOTIFICADO: % (%s) para %', badge_info.name, badge_info.rarity, NEW.user_id;
    
    RETURN NEW;
END;
$function$

