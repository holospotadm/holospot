-- ============================================================================
-- MIGRAÇÃO: Funcionalidade Memórias Vivas
-- Data: 2025-01-06
-- Versão: 1.0
-- Descrição: Implementa o feed especial "Memórias Vivas" para usuários 60+
-- ============================================================================

-- ============================================================================
-- PARTE 1: ALTERAÇÕES NA TABELA COMMUNITIES
-- ============================================================================

-- Adicionar novas colunas na tabela communities
ALTER TABLE public.communities 
ADD COLUMN IF NOT EXISTS is_age_restricted BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS min_age_to_post INTEGER DEFAULT NULL,
ADD COLUMN IF NOT EXISTS allow_multiple_feedbacks BOOLEAN DEFAULT false;

-- Comentários nas colunas
COMMENT ON COLUMN public.communities.is_age_restricted IS 'Se true, a comunidade tem restrição de idade para postagem';
COMMENT ON COLUMN public.communities.min_age_to_post IS 'Idade mínima para postar na comunidade (se is_age_restricted = true)';
COMMENT ON COLUMN public.communities.allow_multiple_feedbacks IS 'Se true, permite múltiplos feedbacks de diferentes usuários em um post';

-- ============================================================================
-- PARTE 2: INSERIR A COMUNIDADE "MEMÓRIAS VIVAS"
-- ============================================================================

-- Primeiro, precisamos de um owner_id válido (usar o primeiro admin ou criar um sistema)
-- Por enquanto, vamos usar um usuário existente como owner
-- NOTA: Substituir pelo ID de um usuário administrador real

INSERT INTO public.communities (
    name,
    slug,
    description,
    emoji,
    is_age_restricted,
    min_age_to_post,
    allow_multiple_feedbacks,
    is_active,
    owner_id
) VALUES (
    'Memórias Vivas',
    'memorias-vivas',
    'Um espaço especial para compartilhar e honrar as histórias e sabedorias dos nossos membros com 60+ anos. Aqui, a experiência de vida é celebrada e as memórias ganham voz.',
    '📖',
    true,
    60,
    true,
    true,
    (SELECT id FROM public.profiles ORDER BY created_at ASC LIMIT 1) -- Usar o primeiro usuário como owner
) ON CONFLICT (slug) DO UPDATE SET
    is_age_restricted = EXCLUDED.is_age_restricted,
    min_age_to_post = EXCLUDED.min_age_to_post,
    allow_multiple_feedbacks = EXCLUDED.allow_multiple_feedbacks;

-- ============================================================================
-- PARTE 3: ADICIONAR NOVOS BADGES
-- ============================================================================

-- Badges para quem POSTA (60+)
INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity, points_required) VALUES
('Contador de Histórias', 'Compartilhou sua primeira história no Memórias Vivas', '📖', 'memorias_vivas', 'memorias_vivas_posts', 1, 'common', 0),
('Guardião de Memórias', 'Compartilhou 10 histórias no Memórias Vivas', '🏛️', 'memorias_vivas', 'memorias_vivas_posts', 10, 'rare', 0),
('Sábio', 'Compartilhou 50 histórias no Memórias Vivas', '👑', 'memorias_vivas', 'memorias_vivas_posts', 50, 'epic', 0),
('Inspirador', 'Recebeu 100+ reações em posts do Memórias Vivas', '⭐', 'memorias_vivas', 'memorias_vivas_reactions_received', 100, 'legendary', 0)
ON CONFLICT DO NOTHING;

-- Badges para quem INTERAGE (qualquer idade)
INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity, points_required) VALUES
('Ouvinte', 'Reagiu a 10 posts do Memórias Vivas', '👂', 'memorias_vivas', 'memorias_vivas_reactions_given', 10, 'common', 0),
('Curioso', 'Comentou em 10 posts do Memórias Vivas', '💬', 'memorias_vivas', 'memorias_vivas_comments', 10, 'common', 0),
('Conectado às Raízes', 'Interagiu com 50 posts do Memórias Vivas', '🤝', 'memorias_vivas', 'memorias_vivas_interactions', 50, 'rare', 0),
('Honrador', 'Reagiu a 100 posts do Memórias Vivas', '💖', 'memorias_vivas', 'memorias_vivas_reactions_given', 100, 'epic', 0)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PARTE 4: CRIAR FUNÇÃO AUXILIAR PARA VERIFICAR COMUNIDADE MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_memorias_vivas_community_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
    SELECT id FROM public.communities WHERE slug = 'memorias-vivas' LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_memorias_vivas_community_id() IS 'Retorna o ID da comunidade Memórias Vivas';

-- ============================================================================
-- PARTE 5: CRIAR FUNÇÃO PARA VERIFICAR SE USUÁRIO PODE POSTAR NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.can_post_in_memorias_vivas(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    user_age INTEGER;
BEGIN
    SELECT calculate_age(birth_date) INTO user_age
    FROM public.profiles
    WHERE id = user_id;
    
    RETURN COALESCE(user_age, 0) >= 60;
END;
$$;

COMMENT ON FUNCTION public.can_post_in_memorias_vivas(UUID) IS 'Verifica se o usuário tem 60+ anos e pode postar no Memórias Vivas';

-- ============================================================================
-- PARTE 6: CRIAR FUNÇÃO PARA VERIFICAR SE USUÁRIO PODE DAR FEEDBACK NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.can_give_feedback_in_memorias_vivas(user_id UUID, target_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    user_age INTEGER;
    post_community_id UUID;
    memorias_vivas_id UUID;
BEGIN
    -- Buscar idade do usuário
    SELECT calculate_age(birth_date) INTO user_age
    FROM public.profiles
    WHERE id = user_id;
    
    -- Buscar community_id do post
    SELECT community_id INTO post_community_id
    FROM public.posts
    WHERE id = target_post_id;
    
    -- Buscar ID do Memórias Vivas
    SELECT get_memorias_vivas_community_id() INTO memorias_vivas_id;
    
    -- Verificar se o post é do Memórias Vivas E se o usuário tem 60+
    RETURN post_community_id = memorias_vivas_id AND COALESCE(user_age, 0) >= 60;
END;
$$;

COMMENT ON FUNCTION public.can_give_feedback_in_memorias_vivas(UUID, UUID) IS 'Verifica se o usuário pode dar feedback em um post do Memórias Vivas (60+ apenas)';

-- ============================================================================
-- PARTE 7: POLICIES RLS PARA POSTS
-- ============================================================================

-- Remover policy antiga se existir
DROP POLICY IF EXISTS "Allow 60+ to post in Memórias Vivas" ON public.posts;

-- Criar policy para INSERT em posts do Memórias Vivas
-- Esta policy permite:
-- 1. Posts em qualquer comunidade que NÃO seja Memórias Vivas
-- 2. Posts no Memórias Vivas APENAS se o usuário tiver 60+
CREATE POLICY "posts_memorias_vivas_insert" ON public.posts
FOR INSERT
WITH CHECK (
    community_id IS NULL 
    OR community_id != get_memorias_vivas_community_id()
    OR can_post_in_memorias_vivas(auth.uid())
);

-- ============================================================================
-- PARTE 8: POLICIES RLS PARA FEEDBACKS
-- ============================================================================

-- Remover policy antiga se existir
DROP POLICY IF EXISTS "Allow 60+ to give feedback in Memórias Vivas" ON public.feedbacks;

-- Criar policy para INSERT em feedbacks do Memórias Vivas
-- Esta policy permite:
-- 1. Feedbacks em posts que NÃO são do Memórias Vivas (regra normal: apenas mentioned_user)
-- 2. Feedbacks em posts do Memórias Vivas se o usuário tiver 60+
CREATE POLICY "feedbacks_memorias_vivas_insert" ON public.feedbacks
FOR INSERT
WITH CHECK (
    -- Se o post NÃO é do Memórias Vivas, usar regra normal
    (SELECT community_id FROM public.posts WHERE id = post_id) != get_memorias_vivas_community_id()
    OR
    -- Se o post É do Memórias Vivas, verificar se usuário tem 60+
    can_give_feedback_in_memorias_vivas(auth.uid(), post_id)
);

-- ============================================================================
-- PARTE 9: FUNÇÃO PARA CONTAR POSTS DO USUÁRIO NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_posts(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.posts
    WHERE user_id = $1
    AND community_id = get_memorias_vivas_community_id();
$$;

-- ============================================================================
-- PARTE 10: FUNÇÃO PARA CONTAR REAÇÕES RECEBIDAS NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_reactions_received(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.reactions r
    JOIN public.posts p ON r.post_id = p.id
    WHERE p.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;

-- ============================================================================
-- PARTE 11: FUNÇÃO PARA CONTAR REAÇÕES DADAS NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_reactions_given(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.reactions r
    JOIN public.posts p ON r.post_id = p.id
    WHERE r.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;

-- ============================================================================
-- PARTE 12: FUNÇÃO PARA CONTAR COMENTÁRIOS NO MEMÓRIAS VIVAS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_memorias_vivas_comments(user_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM public.comments c
    JOIN public.posts p ON c.post_id = p.id
    WHERE c.user_id = $1
    AND p.community_id = get_memorias_vivas_community_id();
$$;

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================

-- Verificar se a comunidade foi criada
SELECT id, name, slug, emoji, is_age_restricted, min_age_to_post, allow_multiple_feedbacks
FROM public.communities
WHERE slug = 'memorias-vivas';

-- Verificar se os badges foram criados
SELECT name, icon, category, condition_type, condition_value
FROM public.badges
WHERE category = 'memorias_vivas';


-- ============================================================================
-- PARTE 13: TRIGGER PARA VERIFICAR BADGES DO MEMÓRIAS VIVAS
-- ============================================================================

-- Função para verificar e conceder badges do Memórias Vivas
CREATE OR REPLACE FUNCTION public.check_memorias_vivas_badges()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    memorias_vivas_id UUID;
    user_to_check UUID;
    posts_count INTEGER;
    reactions_received INTEGER;
    reactions_given INTEGER;
    comments_count INTEGER;
    interactions_count INTEGER;
    badge_record RECORD;
BEGIN
    -- Buscar ID do Memórias Vivas
    SELECT get_memorias_vivas_community_id() INTO memorias_vivas_id;
    
    -- Se não existe Memórias Vivas, sair
    IF memorias_vivas_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Determinar qual usuário verificar baseado na tabela
    IF TG_TABLE_NAME = 'posts' THEN
        -- Verificar se o post é do Memórias Vivas
        IF NEW.community_id != memorias_vivas_id THEN
            RETURN NEW;
        END IF;
        user_to_check := NEW.user_id;
        
        -- Contar posts do usuário no Memórias Vivas
        posts_count := count_user_memorias_vivas_posts(user_to_check);
        
        -- Verificar badges de posts
        FOR badge_record IN 
            SELECT id, condition_value 
            FROM public.badges 
            WHERE category = 'memorias_vivas' 
            AND condition_type = 'memorias_vivas_posts'
        LOOP
            IF posts_count >= badge_record.condition_value THEN
                INSERT INTO public.user_badges (user_id, badge_id)
                VALUES (user_to_check, badge_record.id)
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
        
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        -- Buscar o post para verificar se é do Memórias Vivas
        DECLARE
            post_community_id UUID;
            post_owner_id UUID;
        BEGIN
            SELECT community_id, user_id INTO post_community_id, post_owner_id
            FROM public.posts WHERE id = NEW.post_id;
            
            IF post_community_id != memorias_vivas_id THEN
                RETURN NEW;
            END IF;
            
            -- Verificar badges para quem DEU a reação
            reactions_given := count_user_memorias_vivas_reactions_given(NEW.user_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_reactions_given'
            LOOP
                IF reactions_given >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (NEW.user_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badges para quem RECEBEU a reação (dono do post)
            reactions_received := count_user_memorias_vivas_reactions_received(post_owner_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_reactions_received'
            LOOP
                IF reactions_received >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (post_owner_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badge de interações (reações + comentários)
            interactions_count := reactions_given + count_user_memorias_vivas_comments(NEW.user_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_interactions'
            LOOP
                IF interactions_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (NEW.user_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END;
        
    ELSIF TG_TABLE_NAME = 'comments' THEN
        -- Buscar o post para verificar se é do Memórias Vivas
        DECLARE
            post_community_id UUID;
        BEGIN
            SELECT community_id INTO post_community_id
            FROM public.posts WHERE id = NEW.post_id;
            
            IF post_community_id != memorias_vivas_id THEN
                RETURN NEW;
            END IF;
            
            user_to_check := NEW.user_id;
            
            -- Contar comentários do usuário no Memórias Vivas
            comments_count := count_user_memorias_vivas_comments(user_to_check);
            
            -- Verificar badges de comentários
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_comments'
            LOOP
                IF comments_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (user_to_check, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badge de interações
            interactions_count := comments_count + count_user_memorias_vivas_reactions_given(user_to_check);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_interactions'
            LOOP
                IF interactions_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (user_to_check, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.check_memorias_vivas_badges() IS 'Verifica e concede badges relacionados ao Memórias Vivas';

-- ============================================================================
-- PARTE 14: CRIAR TRIGGERS PARA VERIFICAÇÃO DE BADGES
-- ============================================================================

-- Trigger para posts
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_posts ON public.posts;
CREATE TRIGGER check_memorias_vivas_badges_on_posts
    AFTER INSERT ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();

-- Trigger para reactions
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_reactions ON public.reactions;
CREATE TRIGGER check_memorias_vivas_badges_on_reactions
    AFTER INSERT ON public.reactions
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();

-- Trigger para comments
DROP TRIGGER IF EXISTS check_memorias_vivas_badges_on_comments ON public.comments;
CREATE TRIGGER check_memorias_vivas_badges_on_comments
    AFTER INSERT ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION check_memorias_vivas_badges();

-- ============================================================================
-- VERIFICAÇÃO FINAL DOS TRIGGERS
-- ============================================================================

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%memorias_vivas%';
