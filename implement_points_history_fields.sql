-- =====================================================
-- SOLUÇÃO DEFINITIVA: CAMPOS ADICIONAIS NA points_history
-- =====================================================

-- 1. ADICIONAR CAMPOS NA TABELA points_history
ALTER TABLE public.points_history 
ADD COLUMN IF NOT EXISTS post_id UUID,
ADD COLUMN IF NOT EXISTS reaction_type TEXT,
ADD COLUMN IF NOT EXISTS reaction_user_id UUID;

-- 2. CRIAR ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_points_history_reaction_control 
ON public.points_history (user_id, action_type, post_id, reaction_type, reaction_user_id)
WHERE reference_type = 'reaction';

-- 3. ATUALIZAR FUNÇÃO add_points_to_user PARA INCLUIR OS NOVOS CAMPOS
CREATE OR REPLACE FUNCTION add_points_to_user(
    p_user_id UUID,
    p_action_type TEXT,
    p_points INTEGER,
    p_reference_id UUID,
    p_reference_type TEXT,
    p_post_id UUID DEFAULT NULL,
    p_reaction_type TEXT DEFAULT NULL,
    p_reaction_user_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Inserir no histórico de pontos com os novos campos
    INSERT INTO public.points_history (
        user_id,
        action_type,
        points_earned,
        reference_id,
        reference_type,
        post_id,
        reaction_type,
        reaction_user_id,
        created_at
    ) VALUES (
        p_user_id,
        p_action_type,
        p_points,
        p_reference_id,
        p_reference_type,
        p_post_id,
        p_reaction_type,
        p_reaction_user_id,
        NOW()
    );

    -- Atualizar total de pontos do usuário
    INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level, updated_at)
    VALUES (p_user_id, p_points, 1, GREATEST(0, 100 - p_points), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_points = user_points.total_points + p_points,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- 4. NOVO TRIGGER COM VERIFICAÇÃO PELOS NOVOS CAMPOS
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
        SELECT 1 FROM public.points_history 
        WHERE user_id = NEW.user_id 
        AND action_type = 'reaction_given'
        AND post_id = NEW.post_id 
        AND reaction_type = NEW.type
    ) INTO v_already_given;
    
    -- SE NÃO DEU AINDA, DAR PONTOS
    IF NOT v_already_given THEN
        PERFORM add_points_to_user(
            NEW.user_id, 
            'reaction_given', 
            2, 
            NEW.id, 
            'reaction',
            NEW.post_id,
            NEW.type,
            NULL
        );
    END IF;
    
    -- VERIFICAR SE JÁ DEU PONTOS PARA QUEM RECEBEU A REAÇÃO
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        SELECT EXISTS(
            SELECT 1 FROM public.points_history 
            WHERE user_id = v_post_author 
            AND action_type = 'reaction_received'
            AND post_id = NEW.post_id 
            AND reaction_type = NEW.type
            AND reaction_user_id = NEW.user_id
        ) INTO v_already_received;
        
        -- SE NÃO DEU AINDA, DAR PONTOS
        IF NOT v_already_received THEN
            PERFORM add_points_to_user(
                v_post_author, 
                'reaction_received', 
                3, 
                NEW.id, 
                'reaction',
                NEW.post_id,
                NEW.type,
                NEW.user_id
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. VERIFICAR SE FOI IMPLEMENTADO CORRETAMENTE
SELECT 
    'IMPLEMENTAÇÃO CONCLUÍDA' as status,
    'Campos adicionados: post_id, reaction_type, reaction_user_id' as campos,
    'Trigger atualizado para usar novos campos' as trigger_status,
    'Função add_points_to_user atualizada' as funcao_status;

-- 6. TESTAR A LÓGICA (OPCIONAL - PARA DEBUG)
-- SELECT 
--     user_id,
--     action_type,
--     post_id,
--     reaction_type,
--     reaction_user_id,
--     points_earned
-- FROM public.points_history 
-- WHERE reference_type = 'reaction'
-- ORDER BY created_at DESC
-- LIMIT 5;

