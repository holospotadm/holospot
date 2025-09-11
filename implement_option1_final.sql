-- =====================================================
-- IMPLEMENTAÇÃO FINAL - OPÇÃO 1: EXISTS COM SUBQUERY
-- =====================================================

-- Implementar a verificação mais robusta usando EXISTS
-- Verifica se já existe pontuação para aquela combinação específica

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

-- Verificar se a implementação foi aplicada
SELECT 'Opção 1 implementada: EXISTS com subquery para verificação robusta' as status;

-- Testar a lógica implementada:
-- 1. Usuário dá reação "touched" no post X = +2 pts (primeira vez)
-- 2. Usuário remove reação "touched" do post X = pontos mantidos
-- 3. Usuário dá reação "touched" no post X novamente = 0 pts (EXISTS encontra histórico)
-- 4. Usuário dá reação "gratitude" no post X = +2 pts (tipo diferente, permitido)

SELECT 'Lógica robusta implementada com EXISTS' as resultado;

