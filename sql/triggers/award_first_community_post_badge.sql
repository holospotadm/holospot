-- ============================================
-- TRIGGER: award_first_community_post_badge
-- Descrição: Atribui badge ao primeiro post em comunidade
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- Função do trigger
CREATE OR REPLACE FUNCTION award_first_community_post_badge()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.community_id IS NOT NULL THEN
        -- Verificar se é o primeiro post do usuário nesta comunidade
        IF NOT EXISTS (
            SELECT 1 FROM posts 
            WHERE user_id = NEW.user_id 
            AND community_id = NEW.community_id 
            AND id != NEW.id
        ) THEN
            INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
            VALUES (
                NEW.user_id,
                'Primeiro Post na Comunidade',
                'Fez o primeiro post em uma comunidade',
                NOW()
            )
            ON CONFLICT (user_id, badge_name) DO NOTHING;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Drop trigger se existir
DROP TRIGGER IF EXISTS trigger_award_first_community_post_badge ON posts;

-- Criar trigger
CREATE TRIGGER trigger_award_first_community_post_badge
AFTER INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION award_first_community_post_badge();

-- Comentário
COMMENT ON FUNCTION award_first_community_post_badge IS 'Atribui badge ao fazer primeiro post em comunidade';

