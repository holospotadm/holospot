-- ============================================================================
-- FUNÇÃO: handle_comment
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_comment()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Inserir pontos para quem comentou
        INSERT INTO public.points_history (
            user_id, points_earned, action_type, reference_id, reference_type, post_id, created_at
        ) VALUES (
            NEW.user_id, 7, 'comment_given', NEW.id::text::uuid, 'comment', NEW.post_id, NOW()
        );
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$function$

