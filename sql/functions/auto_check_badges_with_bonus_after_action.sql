-- ============================================================================
-- FUNÇÃO: auto_check_badges_with_bonus_after_action
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_check_badges_with_bonus_after_action()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    affected_user_id UUID;
    post_owner_id UUID;
    result_text TEXT;
BEGIN
    -- Determinar qual usuário foi afetado baseado na tabela e operação
    IF TG_TABLE_NAME = 'posts' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar usuário mencionado se houver
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'comments' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.user_id;
            -- Também verificar dono do post
            SELECT user_id INTO post_owner_id FROM public.posts WHERE id = NEW.post_id;
            IF post_owner_id IS NOT NULL AND post_owner_id != NEW.user_id THEN
                SELECT check_and_grant_badges_with_bonus(post_owner_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'feedbacks' THEN
        IF TG_OP = 'INSERT' THEN
            affected_user_id := NEW.author_id;
            -- Também verificar usuário mencionado
            IF NEW.mentioned_user_id IS NOT NULL THEN
                SELECT check_and_grant_badges_with_bonus(NEW.mentioned_user_id) INTO result_text;
            END IF;
        END IF;
    ELSIF TG_TABLE_NAME = 'user_points' THEN
        IF TG_OP = 'UPDATE' THEN
            affected_user_id := NEW.user_id;
        END IF;
    END IF;
    
    -- Verificar badges para o usuário principal afetado
    IF affected_user_id IS NOT NULL THEN
        SELECT check_and_grant_badges_with_bonus(affected_user_id) INTO result_text;
        IF result_text != 'Nenhum badge novo concedido' THEN
            RAISE NOTICE 'Auto-check badges com bônus: %', result_text;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$function$

