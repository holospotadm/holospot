-- ============================================================================
-- FUNÇÃO: add_post_to_chain
-- ============================================================================

CREATE OR REPLACE FUNCTION public.add_post_to_chain(p_chain_id uuid, p_post_id uuid, p_author_id uuid, p_parent_post_author_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_chain_status TEXT;
    v_chain_creator_id UUID;
    v_is_first_post BOOLEAN;
BEGIN
    SELECT status, creator_id
    INTO v_chain_status, v_chain_creator_id
    FROM public.chains
    WHERE id = p_chain_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Corrente não encontrada: %', p_chain_id;
    END IF;
    
    v_is_first_post := (p_parent_post_author_id IS NULL AND p_author_id = v_chain_creator_id);
    
    IF v_is_first_post THEN
        IF v_chain_status != 'pending' THEN
            RAISE EXCEPTION 'Corrente já foi iniciada (status: %)', v_chain_status;
        END IF;
    ELSE
        IF v_chain_status != 'active' THEN
            RAISE EXCEPTION 'Corrente não está ativa para participação (status: %)', v_chain_status;
        END IF;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.posts WHERE id = p_post_id) THEN
        RAISE EXCEPTION 'Post não encontrado: %', p_post_id;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_author_id) THEN
        RAISE EXCEPTION 'Autor não encontrado: %', p_author_id;
    END IF;
    
    IF p_parent_post_author_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_parent_post_author_id) THEN
            RAISE EXCEPTION 'Autor do post pai não encontrado: %', p_parent_post_author_id;
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM public.chain_posts
            WHERE chain_id = p_chain_id AND author_id = p_parent_post_author_id
        ) THEN
            RAISE EXCEPTION 'Autor do post pai não participa desta corrente';
        END IF;
    END IF;
    
    INSERT INTO public.chain_posts (chain_id, post_id, author_id, parent_post_author_id)
    VALUES (p_chain_id, p_post_id, p_author_id, p_parent_post_author_id);
    
    UPDATE public.posts SET chain_id = p_chain_id WHERE id = p_post_id;
    
    IF v_is_first_post THEN
        UPDATE public.chains
        SET first_post_id = p_post_id, status = 'active', start_date = NOW()
        WHERE id = p_chain_id;
    END IF;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Post já está associado a uma corrente';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao adicionar post à corrente: %', SQLERRM;
END;
$function$

