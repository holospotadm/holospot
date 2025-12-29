-- ============================================================================
-- FUNÇÃO: close_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.close_chain(p_chain_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_creator_id UUID;
    v_status TEXT;
BEGIN
    SELECT creator_id, status
    INTO v_creator_id, v_status
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    IF v_creator_id != p_user_id THEN
        RAISE EXCEPTION 'Apenas o criador pode fechar a corrente';
    END IF;
    
    IF v_status != 'active' THEN
        RAISE EXCEPTION 'Apenas correntes ativas podem ser fechadas (status atual: %)', v_status;
    END IF;
    
    UPDATE public.chains
    SET status = 'closed', end_date = NOW()
    WHERE id = p_chain_id;
    
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao fechar corrente: %', SQLERRM;
END;
$function$

