-- ============================================================================
-- FUNÇÃO: cancel_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.cancel_chain(p_chain_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_creator_id UUID;
    v_status TEXT;
    v_first_post_id UUID;
BEGIN
    SELECT creator_id, status, first_post_id
    INTO v_creator_id, v_status, v_first_post_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode cancelar a corrente';
    END IF;
    
    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Apenas correntes pendentes podem ser canceladas (status atual: %)', v_status;
    END IF;
    
    IF v_first_post_id IS NOT NULL THEN
        RAISE EXCEPTION 'Corrente já possui posts associados e não pode ser cancelada';
    END IF;
    
    DELETE FROM public.chains WHERE id = p_chain_id;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao cancelar corrente: %', SQLERRM;
END;
$function$

