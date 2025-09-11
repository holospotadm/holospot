-- =====================================================
-- VERIFICAÇÃO SIMPLES NO POINTS_HISTORY SEM JOINS COMPLEXOS
-- =====================================================

-- Problema: JOIN complexo pode estar falhando
-- Solução: Verificar no points_history de forma mais direta
-- Usar uma subquery para verificar se já existe pontuação para aquela combinação

CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_existing_points INTEGER;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- VERIFICAR SE JÁ EXISTE PONTUAÇÃO PARA ESTA COMBINAÇÃO ESPECÍFICA
    -- Buscar por reações do mesmo usuário, no mesmo post, do mesmo tipo
    SELECT COUNT(*) INTO v_existing_points 
    FROM public.points_history ph
    WHERE ph.user_id = NEW.user_id 
    AND ph.action_type = 'reaction_given'
    AND ph.reference_type = 'reaction'
    AND EXISTS (
        SELECT 1 FROM public.reactions r 
        WHERE r.id = ph.reference_id 
        AND r.post_id = NEW.post_id 
        AND r.type = NEW.type
        AND r.user_id = NEW.user_id
    );
    
    -- SÓ ADICIONAR PONTOS SE NÃO EXISTE HISTÓRICO ANTERIOR
    IF v_existing_points = 0 THEN
        -- Adicionar pontos para quem deu a reação
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        -- Adicionar pontos para quem recebeu a reação (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            -- Verificar se já existe pontuação para receber esta reação específica
            SELECT COUNT(*) INTO v_existing_points 
            FROM public.points_history ph
            WHERE ph.user_id = v_post_author 
            AND ph.action_type = 'reaction_received'
            AND ph.reference_type = 'reaction'
            AND EXISTS (
                SELECT 1 FROM public.reactions r 
                WHERE r.id = ph.reference_id 
                AND r.post_id = NEW.post_id 
                AND r.type = NEW.type
                AND r.user_id = NEW.user_id
            );
            
            IF v_existing_points = 0 THEN
                PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Alternativa ainda mais simples: verificar apenas por contagem de reações similares no histórico
CREATE OR REPLACE FUNCTION trigger_reaction_given_simple()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_similar_reactions INTEGER;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- CONTAR QUANTAS VEZES ESTE USUÁRIO JÁ DEU ESTE TIPO DE REAÇÃO NESTE POST
    -- Buscar no histórico por reações similares
    SELECT COUNT(*) INTO v_similar_reactions
    FROM public.points_history ph
    JOIN public.reactions r ON ph.reference_id = r.id
    WHERE ph.user_id = NEW.user_id
    AND ph.action_type = 'reaction_given'
    AND r.post_id = NEW.post_id
    AND r.type = NEW.type;
    
    -- SÓ DAR PONTOS SE É A PRIMEIRA VEZ
    IF v_similar_reactions = 0 THEN
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            -- Contar se autor já recebeu este tipo de reação deste usuário neste post
            SELECT COUNT(*) INTO v_similar_reactions
            FROM public.points_history ph
            JOIN public.reactions r ON ph.reference_id = r.id
            WHERE ph.user_id = v_post_author
            AND ph.action_type = 'reaction_received'
            AND r.post_id = NEW.post_id
            AND r.type = NEW.type
            AND r.user_id = NEW.user_id;
            
            IF v_similar_reactions = 0 THEN
                PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Escolher qual função usar (a primeira é mais robusta, a segunda mais simples)
-- Para usar a primeira: trigger_reaction_given()
-- Para usar a segunda: trigger_reaction_given_simple()

SELECT 'Duas opções criadas - escolher qual usar' as status;

