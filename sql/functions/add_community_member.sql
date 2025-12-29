-- ============================================================================
-- FUNÇÃO: add_community_member
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_community_member(p_community_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can add members';
    END IF;
    
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, 'member')
    ON CONFLICT (community_id, user_id) DO UPDATE
    SET is_active = true;
    
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_user_id,
        'Membro de Comunidade',
        'Entrou em uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN true;
END;
$function$

