-- ============================================================================
-- FUNÇÃO: handle_feedback_insert_secure
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_feedback_insert_secure()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Quem foi mencionado (deu feedback) ganha 10 pontos
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM add_points_secure(
            NEW.mentioned_user_id, 10, 'feedback_given', 
            md5('feedback_' || NEW.id::text)::uuid, 'feedback', NEW.post_id, NULL, NEW.mentioned_user_id
        );
    END IF;
    
    -- Quem escreveu (recebeu feedback) ganha 8 pontos
    PERFORM add_points_secure(
        NEW.author_id, 8, 'feedback_received', 
        md5('feedback_' || NEW.id::text)::uuid, 'feedback', NEW.post_id, NULL, NEW.mentioned_user_id
    );
    
    -- Recalcular pontos
    IF NEW.mentioned_user_id IS NOT NULL THEN
        PERFORM recalculate_user_points_secure(NEW.mentioned_user_id);
    END IF;
    PERFORM recalculate_user_points_secure(NEW.author_id);
    
    RETURN NEW;
END;
$function$

