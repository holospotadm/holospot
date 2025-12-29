-- ============================================================================
-- FUNÇÃO: trigger_feedback_removed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_feedback_removed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Remover pontos de quem foi mencionado (deu feedback)
    IF OLD.mentioned_user_id IS NOT NULL THEN
        DELETE FROM public.points_history 
        WHERE user_id = OLD.mentioned_user_id 
        AND action_type = 'feedback_given' 
        AND reference_id = md5('feedback_' || OLD.id::text)::uuid;
    END IF;
    
    -- Remover pontos de quem escreveu o feedback
    DELETE FROM public.points_history 
    WHERE user_id = OLD.author_id 
    AND action_type = 'feedback_received' 
    AND reference_id = md5('feedback_' || OLD.id::text)::uuid;
    
    RETURN OLD;
END;
$function$

