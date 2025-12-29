-- ============================================================================
-- FUNÇÃO: get_chain_info
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_chain_info(p_chain_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_chain_info JSON;
    v_total_posts INTEGER;
    v_total_participants INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.chains WHERE id = p_chain_id) THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    SELECT COUNT(*) INTO v_total_posts
    FROM public.chain_posts WHERE chain_id = p_chain_id;
    
    SELECT COUNT(DISTINCT author_id) INTO v_total_participants
    FROM public.chain_posts WHERE chain_id = p_chain_id;
    
    SELECT json_build_object(
        'id', c.id,
        'name', c.name,
        'description', c.description,
        'highlight_type', c.highlight_type,
        'status', c.status,
        'creator_id', c.creator_id,
        'first_post_id', c.first_post_id,
        'start_date', c.start_date,
        'end_date', c.end_date,
        'created_at', c.created_at,
        'total_posts', v_total_posts,
        'total_participants', v_total_participants
    )
    INTO v_chain_info
    FROM public.chains c
    WHERE c.id = p_chain_id;
    
    RETURN v_chain_info;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao buscar informações da corrente: %', SQLERRM;
END;
$function$

