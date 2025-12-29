-- ============================================================================
-- FUNÇÃO: create_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_chain(p_creator_id uuid, p_name text, p_description text, p_highlight_type text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_chain_id UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_creator_id) THEN
        RAISE EXCEPTION 'Criador não encontrado: %', p_creator_id;
    END IF;
    
    IF char_length(p_name) < 3 OR char_length(p_name) > 50 THEN
        RAISE EXCEPTION 'Nome da corrente deve ter entre 3 e 50 caracteres';
    END IF;
    
    IF char_length(p_description) < 10 OR char_length(p_description) > 200 THEN
        RAISE EXCEPTION 'Descrição da corrente deve ter entre 10 e 200 caracteres';
    END IF;
    
    IF p_highlight_type IS NULL OR trim(p_highlight_type) = '' THEN
        RAISE EXCEPTION 'Tipo de destaque é obrigatório';
    END IF;
    
    INSERT INTO public.chains (
        creator_id, name, description, highlight_type, status, first_post_id
    ) VALUES (
        p_creator_id, trim(p_name), trim(p_description), p_highlight_type, 'pending', NULL
    )
    RETURNING id INTO v_chain_id;
    
    RETURN v_chain_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao criar corrente: %', SQLERRM;
END;
$function$

