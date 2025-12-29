-- ============================================================================
-- FUNÇÃO: trigger_comment_created
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_comment_created()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO public.points_history (user_id, action_type, points_earned, reference_id, reference_type, created_at)
    VALUES (NEW.user_id, 'comment_written', 5, NEW.id, 'comment', NOW());
    
    UPDATE public.user_points SET total_points = total_points + 5, updated_at = NOW() WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$function$

