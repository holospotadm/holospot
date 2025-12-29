-- ============================================================================
-- FUNÇÃO: update_conversation_timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp(conversation_id_param uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE conversations
  SET updated_at = NOW()
  WHERE id = conversation_id_param;
END;
$function$

