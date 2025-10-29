-- ============================================
-- MIGRATION: Corrigir badges de comunidades
-- Descrição: Adiciona badges de comunidades e corrige funções
-- Autor: HoloSpot Team
-- Data: 2024-10-29
-- ============================================

-- 1. Criar badges de comunidades
-- Inserir badges apenas se não existirem
INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity)
SELECT 'Owner de Comunidade', 'Criou uma comunidade no HoloSpot', '👑', 'comunidade', 'manual', 1, 'rare'
WHERE NOT EXISTS (SELECT 1 FROM badges WHERE name = 'Owner de Comunidade');

INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity)
SELECT 'Membro de Comunidade', 'Entrou em uma comunidade', '👥', 'comunidade', 'manual', 1, 'common'
WHERE NOT EXISTS (SELECT 1 FROM badges WHERE name = 'Membro de Comunidade');

INSERT INTO public.badges (name, description, icon, category, condition_type, condition_value, rarity)
SELECT 'Primeiro Post na Comunidade', 'Fez o primeiro post em uma comunidade', '⭐', 'comunidade', 'manual', 1, 'common'
WHERE NOT EXISTS (SELECT 1 FROM badges WHERE name = 'Primeiro Post na Comunidade');

-- 2. Atualizar função create_community para usar badge_id
CREATE OR REPLACE FUNCTION public.create_community(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_community_id UUID;
    v_is_community_owner BOOLEAN;
    v_badge_id UUID;
BEGIN
    -- Verificar se o usuário está autorizado
    IF auth.uid() != p_owner_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Verificar se o usuário pode criar comunidades
    SELECT community_owner INTO v_is_community_owner
    FROM profiles
    WHERE id = p_owner_id;
    
    IF NOT v_is_community_owner THEN
        RAISE EXCEPTION 'User is not authorized to create communities';
    END IF;
    
    -- Criar comunidade
    INSERT INTO communities (name, slug, description, emoji, owner_id)
    VALUES (p_name, p_slug, p_description, COALESCE(p_emoji, '🏢'), p_owner_id)
    RETURNING id INTO v_community_id;
    
    -- Adicionar owner como membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (v_community_id, p_owner_id, 'owner');
    
    -- Buscar badge_id e atribuir badge
    SELECT id INTO v_badge_id
    FROM badges
    WHERE name = 'Owner de Comunidade'
    LIMIT 1;
    
    IF v_badge_id IS NOT NULL THEN
        INSERT INTO user_badges (user_id, badge_id, earned_at)
        VALUES (p_owner_id, v_badge_id, NOW())
        ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
    
    RETURN v_community_id;
END;
$function$;

-- 3. Atualizar função add_community_member para usar badge_id
CREATE OR REPLACE FUNCTION public.add_community_member(
    p_community_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_is_owner BOOLEAN;
    v_badge_id UUID;
BEGIN
    -- Verificar se quem está adicionando é owner
    SELECT EXISTS (
        SELECT 1 FROM community_members
        WHERE community_id = p_community_id
        AND user_id = auth.uid()
        AND role = 'owner'
    ) INTO v_is_owner;
    
    IF NOT v_is_owner THEN
        RAISE EXCEPTION 'Only community owners can add members';
    END IF;
    
    -- Adicionar membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, p_role)
    ON CONFLICT (community_id, user_id) DO NOTHING;
    
    -- Buscar badge_id e atribuir badge
    SELECT id INTO v_badge_id
    FROM badges
    WHERE name = 'Membro de Comunidade'
    LIMIT 1;
    
    IF v_badge_id IS NOT NULL THEN
        INSERT INTO user_badges (user_id, badge_id, earned_at)
        VALUES (p_user_id, v_badge_id, NOW())
        ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;
    
    RETURN TRUE;
END;
$function$;

-- 4. Atualizar trigger de primeiro post para usar badge_id
CREATE OR REPLACE FUNCTION award_first_community_post_badge()
RETURNS TRIGGER
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
$function$;

-- ============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Badges de comunidades criados';
    RAISE NOTICE '✅ Funções atualizadas para usar badge_id';
    RAISE NOTICE '✅ Trigger atualizado';
END $$;

