-- ============================================================================
-- FUNÇÃO: add_community_member_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_community_member(p_community_id uuid, p_user_id uuid, p_role text DEFAULT 'member'::text)
 RETURNS boolean
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
$function$

