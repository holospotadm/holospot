-- ============================================================================
-- FUNÇÃO: process_notification_batch
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_notification_batch(p_notifications jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    notification_item JSONB;
    created_count INTEGER := 0;
    success BOOLEAN;
BEGIN
    -- Processar cada notificação no lote
    FOR notification_item IN SELECT * FROM jsonb_array_elements(p_notifications)
    LOOP
        -- Tentar criar notificação
        SELECT insert_notification_safe(
            (notification_item->>'user_id')::UUID,
            (notification_item->>'from_user_id')::UUID,
            notification_item->>'type',
            notification_item->>'message',
            COALESCE((notification_item->>'priority')::INTEGER, 1),
            notification_item->>'reference_id'
        ) INTO success;
        
        -- Contar se foi criada
        IF success THEN
            created_count := created_count + 1;
        END IF;
    END LOOP;
    
    RETURN created_count;
END;
$function$

