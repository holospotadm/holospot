-- ============================================================================
-- FUNÇÃO: remove_community_member
-- ============================================================================

CREATE OR REPLACE FUNCTION public.remove_community_member(p_community_id uuid, p_user_id uuid)
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
        RAISE EXCEPTION 'Unauthorized: Only owner can remove members';
    END IF;
    
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Owner cannot remove themselves';
    END IF;
    
    UPDATE community_members
    SET is_active = false
    WHERE community_id = p_community_id AND user_id = p_user_id;
    
    RETURN true;
END;
$function$

