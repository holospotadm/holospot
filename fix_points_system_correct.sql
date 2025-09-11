-- =====================================================
-- CORREÇÃO CORRETA: VERIFICAR POR POST + USUÁRIO + TIPO DE REAÇÃO
-- =====================================================

-- O problema: estava verificando por reference_id (ID da reação)
-- Mas quando reação é deletada e criada novamente, recebe novo ID
-- Solução: verificar por post_id + user_id + tipo_reação

-- 1. CORRIGIR TRIGGER DE REAÇÃO PARA VERIFICAÇÃO CORRETA
CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_existing_points INTEGER;
    v_reaction_type TEXT;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- Obter tipo da reação (assumindo que existe campo 'type' na tabela reactions)
    v_reaction_type := NEW.type;
    
    -- VERIFICAR SE JÁ EXISTE PONTUAÇÃO PARA ESTE USUÁRIO + POST + TIPO DE REAÇÃO
    -- Buscar na points_history por posts que este usuário já reagiu com este tipo
    SELECT COUNT(*) INTO v_existing_points 
    FROM public.points_history ph
    JOIN public.reactions r ON ph.reference_id = r.id
    WHERE ph.user_id = NEW.user_id 
    AND ph.action_type = 'reaction_given'
    AND ph.reference_type = 'reaction'
    AND r.post_id = NEW.post_id
    AND r.type = v_reaction_type;
    
    -- SÓ ADICIONAR PONTOS SE NÃO EXISTE HISTÓRICO ANTERIOR
    IF v_existing_points = 0 THEN
        -- Adicionar pontos para quem deu a reação
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        -- Adicionar pontos para quem recebeu a reação (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            -- Verificar se já existe pontuação para receber esta reação deste usuário neste post
            SELECT COUNT(*) INTO v_existing_points 
            FROM public.points_history ph
            JOIN public.reactions r ON ph.reference_id = r.id
            WHERE ph.user_id = v_post_author 
            AND ph.action_type = 'reaction_received'
            AND ph.reference_type = 'reaction'
            AND r.post_id = NEW.post_id
            AND r.user_id = NEW.user_id
            AND r.type = v_reaction_type;
            
            IF v_existing_points = 0 THEN
                PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verificar se a correção foi aplicada
SELECT 'Trigger corrigido para verificar por post + usuário + tipo de reação' as status;

-- Testar a estrutura da tabela reactions
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'reactions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

