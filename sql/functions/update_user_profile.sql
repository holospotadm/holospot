-- ============================================================================
-- FUNÇÃO: update_user_profile
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_user_profile(p_user_id uuid, p_name text DEFAULT NULL::text, p_username text DEFAULT NULL::text, p_avatar_url text DEFAULT NULL::text, p_default_feed text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_username_available BOOLEAN;
    v_result JSON;
BEGIN
    IF p_username IS NOT NULL THEN
        SELECT check_username_availability(p_username, p_user_id) INTO v_username_available;
        
        IF NOT v_username_available THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Username já está em uso'
            );
        END IF;
    END IF;
    
    UPDATE profiles
    SET
        name = COALESCE(p_name, name),
        username = COALESCE(p_username, username),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        default_feed = COALESCE(p_default_feed, default_feed),
        updated_at = NOW()
    WHERE id = p_user_id;
    
    SELECT json_build_object(
        'success', true,
        'profile', row_to_json(p.*)
    )
    INTO v_result
    FROM profiles p
    WHERE p.id = p_user_id;
    
    RETURN v_result;
END;
$function$

