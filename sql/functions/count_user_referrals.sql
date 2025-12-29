-- ============================================================================
-- FUNÇÃO: count_user_referrals
-- ============================================================================

CREATE OR REPLACE FUNCTION public.count_user_referrals(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM public.user_referrals
        WHERE referrer_id = p_user_id
        AND is_active = true
    );
END;
$function$

