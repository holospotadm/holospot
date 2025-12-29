-- ============================================================================
-- FUNÇÃO: notify_level_up
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_level_up(p_user_id uuid, p_old_level integer, p_new_level integer, p_level_name text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Só notificar se realmente subiu de nível
    IF p_new_level > p_old_level THEN
        RETURN create_notification_smart(
            p_user_id,
            NULL, -- Sem from_user (sistema)
            'level_up',
            '⬆️ Level Up! Você alcançou o nível "' || p_level_name || '" (Nível ' || p_new_level || ')',
            3 -- Prioridade alta
        );
    END IF;
    
    RETURN false;
END;
$function$

