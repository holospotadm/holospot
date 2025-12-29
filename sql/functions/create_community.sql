-- ============================================================================
-- FUNÇÃO: create_community
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_community(p_name text, p_slug text, p_description text, p_emoji text, p_owner_id uuid)
 RETURNS uuid
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
$function$

