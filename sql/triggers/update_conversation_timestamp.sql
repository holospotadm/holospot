-- ============================================================================
-- TRIGGER: update_conversation_timestamp
-- Descrição: Atualiza updated_at da conversa quando uma nova mensagem é enviada
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_conversation_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE public.conversations
    SET updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trigger_update_conversation_timestamp ON public.messages;

CREATE TRIGGER trigger_update_conversation_timestamp
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_timestamp();

COMMENT ON FUNCTION public.update_conversation_timestamp IS 
'Atualiza o timestamp da conversa quando uma nova mensagem é enviada';

