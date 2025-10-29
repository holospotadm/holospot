-- ============================================================================
-- FUNÇÃO: get_or_create_conversation
-- Descrição: Busca ou cria uma conversa entre dois usuários
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_conversation_id UUID;
    v_min_user_id UUID;
    v_max_user_id UUID;
BEGIN
    -- Garantir ordem consistente (user1 < user2)
    IF p_user1_id < p_user2_id THEN
        v_min_user_id := p_user1_id;
        v_max_user_id := p_user2_id;
    ELSE
        v_min_user_id := p_user2_id;
        v_max_user_id := p_user1_id;
    END IF;
    
    -- Buscar conversa existente
    SELECT id INTO v_conversation_id
    FROM public.conversations
    WHERE user1_id = v_min_user_id
    AND user2_id = v_max_user_id;
    
    -- Se não existir, criar nova conversa
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (user1_id, user2_id)
        VALUES (v_min_user_id, v_max_user_id)
        RETURNING id INTO v_conversation_id;
    END IF;
    
    RETURN v_conversation_id;
END;
$function$;

COMMENT ON FUNCTION public.get_or_create_conversation IS 
'Busca ou cria uma conversa entre dois usuários, garantindo ordem consistente dos IDs';

