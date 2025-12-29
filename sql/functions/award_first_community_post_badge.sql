-- ============================================================================
-- FUNÇÃO: award_first_community_post_badge
-- ============================================================================

CREATE OR REPLACE FUNCTION public.award_first_community_post_badge()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_is_first_post BOOLEAN;
    v_badge_id UUID;
BEGIN
    -- Verificar se é o primeiro post do usuário nesta comunidade
    IF NEW.community_id IS NOT NULL THEN
        SELECT NOT EXISTS (
            SELECT 1 FROM posts
            WHERE user_id = NEW.user_id
            AND community_id = NEW.community_id
            AND id != NEW.id
        ) INTO v_is_first_post;
        
        IF v_is_first_post THEN
            -- Buscar badge_id e atribuir badge
            SELECT id INTO v_badge_id
            FROM badges
            WHERE name = 'Primeiro Post na Comunidade'
            LIMIT 1;
            
            IF v_badge_id IS NOT NULL THEN
                INSERT INTO user_badges (user_id, badge_id, earned_at)
                VALUES (NEW.user_id, v_badge_id, NOW())
                ON CONFLICT (user_id, badge_id) DO NOTHING;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$

