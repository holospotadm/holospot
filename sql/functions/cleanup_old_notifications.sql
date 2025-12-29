-- ============================================================================
-- FUNÇÃO: cleanup_old_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cleanup_old_notifications(days_to_keep integer DEFAULT 30)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Deletar notificações antigas
    DELETE FROM public.notifications 
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$function$

