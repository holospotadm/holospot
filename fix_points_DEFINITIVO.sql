-- =====================================================
-- SOLUÇÃO DEFINITIVA - SIMPLES E DIRETA
-- =====================================================

-- PROBLEMA: Verificações complexas não funcionam
-- SOLUÇÃO: Criar tabela de controle simples OU usar abordagem mais direta

-- OPÇÃO A: Tabela de controle (mais segura)
CREATE TABLE IF NOT EXISTS public.reaction_points_control (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    post_id UUID NOT NULL,
    reaction_type TEXT NOT NULL,
    action_type TEXT NOT NULL, -- 'given' ou 'received'
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, post_id, reaction_type, action_type)
);

-- OPÇÃO B: Trigger super simples usando a tabela de controle
CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_already_given BOOLEAN := FALSE;
    v_already_received BOOLEAN := FALSE;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- VERIFICAR SE JÁ DEU PONTOS PARA QUEM DEU A REAÇÃO
    SELECT EXISTS(
        SELECT 1 FROM public.reaction_points_control 
        WHERE user_id = NEW.user_id 
        AND post_id = NEW.post_id 
        AND reaction_type = NEW.type 
        AND action_type = 'given'
    ) INTO v_already_given;
    
    -- SE NÃO DEU AINDA, DAR PONTOS E MARCAR CONTROLE
    IF NOT v_already_given THEN
        -- Dar pontos
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        -- Marcar controle
        INSERT INTO public.reaction_points_control (user_id, post_id, reaction_type, action_type)
        VALUES (NEW.user_id, NEW.post_id, NEW.type, 'given')
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- VERIFICAR SE JÁ DEU PONTOS PARA QUEM RECEBEU A REAÇÃO
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        SELECT EXISTS(
            SELECT 1 FROM public.reaction_points_control 
            WHERE user_id = v_post_author 
            AND post_id = NEW.post_id 
            AND reaction_type = NEW.type 
            AND action_type = 'received'
        ) INTO v_already_received;
        
        -- SE NÃO DEU AINDA, DAR PONTOS E MARCAR CONTROLE
        IF NOT v_already_received THEN
            -- Dar pontos
            PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
            
            -- Marcar controle
            INSERT INTO public.reaction_points_control (user_id, post_id, reaction_type, action_type)
            VALUES (v_post_author, NEW.post_id, NEW.type, 'received')
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- OPÇÃO C: Se não quiser criar tabela, usar verificação mais direta
CREATE OR REPLACE FUNCTION trigger_reaction_given_direct()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_count_given INTEGER;
    v_count_received INTEGER;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- CONTAR DIRETAMENTE: quantas vezes este usuário já ganhou pontos por dar esta reação neste post
    SELECT COUNT(*) INTO v_count_given
    FROM public.points_history ph
    WHERE ph.user_id = NEW.user_id
    AND ph.action_type = 'reaction_given'
    AND ph.reference_type = 'reaction'
    AND ph.reference_id IN (
        SELECT id FROM public.reactions 
        WHERE post_id = NEW.post_id 
        AND type = NEW.type 
        AND user_id = NEW.user_id
    );
    
    -- SE NUNCA GANHOU PONTOS, DAR AGORA
    IF v_count_given = 0 THEN
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
    END IF;
    
    -- MESMO PARA QUEM RECEBEU
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        SELECT COUNT(*) INTO v_count_received
        FROM public.points_history ph
        WHERE ph.user_id = v_post_author
        AND ph.action_type = 'reaction_received'
        AND ph.reference_type = 'reaction'
        AND ph.reference_id IN (
            SELECT id FROM public.reactions 
            WHERE post_id = NEW.post_id 
            AND type = NEW.type 
            AND user_id = NEW.user_id
        );
        
        IF v_count_received = 0 THEN
            PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ESCOLHER QUAL USAR:
-- Para usar OPÇÃO B (com tabela de controle): trigger_reaction_given()
-- Para usar OPÇÃO C (verificação direta): trigger_reaction_given_direct()

SELECT 'DUAS SOLUÇÕES DEFINITIVAS CRIADAS - ESCOLHER UMA' as status;

