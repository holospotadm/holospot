-- ============================================================================
-- FUNÇÃO: auto_group_all_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_group_all_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    user_record RECORD;
    total_grouped INTEGER := 0;
    user_grouped INTEGER;
BEGIN
    -- Para cada usuário com notificações recentes não agrupadas
    FOR user_record IN 
        SELECT DISTINCT user_id 
        FROM public.notifications 
        WHERE created_at >= NOW() - INTERVAL '6 hours'
        AND group_key IS NULL
        AND type = 'reaction'
    LOOP
        -- Executar agrupamento para este usuário
        SELECT group_reaction_notifications(user_record.user_id, 2) INTO user_grouped;
        total_grouped := total_grouped + user_grouped;
    END LOOP;
    
    RETURN total_grouped;
END;
$function$

