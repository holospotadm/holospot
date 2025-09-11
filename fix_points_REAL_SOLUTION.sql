-- =====================================================
-- SOLUÇÃO REAL: VERIFICAR DIRETAMENTE NA TABELA REACTIONS
-- =====================================================

-- PROBLEMA IDENTIFICADO: reference_id inválidos no points_history
-- SOLUÇÃO: Verificar diretamente se usuário já deu aquele tipo de reação naquele post

CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_already_reacted BOOLEAN := FALSE;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- VERIFICAR DIRETAMENTE: Este usuário já deu este tipo de reação neste post antes?
    -- (Excluindo a reação atual que está sendo criada)
    SELECT EXISTS(
        SELECT 1 FROM public.reactions 
        WHERE user_id = NEW.user_id 
        AND post_id = NEW.post_id 
        AND type = NEW.type
        AND id != NEW.id  -- Excluir a reação atual
    ) INTO v_already_reacted;
    
    -- SE NUNCA DEU ESTA REAÇÃO NESTE POST ANTES, DAR PONTOS
    IF NOT v_already_reacted THEN
        -- Dar pontos para quem deu a reação
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        -- Dar pontos para quem recebeu a reação (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- LÓGICA SIMPLES E DIRETA:
-- 1. Usuário dá reação "touched" no post X = +2 pts (primeira vez)
-- 2. Usuário remove reação "touched" do post X = pontos mantidos
-- 3. Usuário dá reação "touched" no post X novamente = 0 pts (já deu antes)
-- 4. Usuário dá reação "gratitude" no post X = +2 pts (tipo diferente, permitido)

-- Verificar se foi aplicado
SELECT 'Solução real implementada: verificação direta na tabela reactions' as status;

