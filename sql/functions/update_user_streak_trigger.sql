-- ============================================================================
-- FUNÇÃO: update_user_streak_trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_streak_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Atualizar streak do usuário que fez a atividade
    -- CORREÇÃO: Para feedbacks, usar NEW.author_id em vez de NEW.user_id
    IF TG_TABLE_NAME = 'feedbacks' THEN
        PERFORM update_user_streak(NEW.author_id);
        -- Para feedbacks, também atualizar streak do usuário mencionado
        IF NEW.mentioned_user_id IS NOT NULL THEN
            PERFORM update_user_streak(NEW.mentioned_user_id);
        END IF;
    ELSE
        -- Para outras tabelas (posts, comments, reactions), usar NEW.user_id
        PERFORM update_user_streak(NEW.user_id);
    END IF;
    
    RETURN NEW;
END;
$function$

