-- ============================================================================
-- FUNÇÃO: update_conversation_timestamp_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$function$

