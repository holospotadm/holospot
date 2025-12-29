-- ============================================================================
-- FUNÇÃO: update_community
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_community(p_community_id uuid, p_name text, p_slug text, p_description text, p_emoji text, p_logo_url text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM communities 
        WHERE id = p_community_id 
        AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can update community';
    END IF;
    
    UPDATE communities
    SET 
        name = p_name,
        slug = p_slug,
        description = p_description,
        emoji = COALESCE(p_emoji, emoji),
        logo_url = p_logo_url,
        updated_at = NOW()
    WHERE id = p_community_id;
    
    RETURN true;
END;
$function$

