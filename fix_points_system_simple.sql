-- =====================================================
-- ABORDAGEM MAIS SIMPLES: VERIFICAR DIRETAMENTE NA TABELA REACTIONS
-- =====================================================

-- Problema: A verificação via points_history pode estar falhando
-- Solução: Verificar diretamente se já existe reação deste tipo, deste usuário, neste post

-- NOVA ABORDAGEM: Adicionar campo de controle na tabela points_history
-- Usar combinação única: user_id + post_id + reaction_type + action_type

CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_existing_reaction_given INTEGER;
    v_existing_reaction_received INTEGER;
    v_unique_key_given TEXT;
    v_unique_key_received TEXT;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- Criar chaves únicas para verificação
    v_unique_key_given := NEW.user_id::text || '_' || NEW.post_id::text || '_' || NEW.type || '_reaction_given';
    v_unique_key_received := v_post_author::text || '_' || NEW.post_id::text || '_' || NEW.type || '_reaction_received_from_' || NEW.user_id::text;
    
    -- VERIFICAR SE JÁ EXISTE PONTUAÇÃO PARA REACTION_GIVEN
    -- Usar uma abordagem mais direta: verificar por chave única no campo description ou criar campo custom
    SELECT COUNT(*) INTO v_existing_reaction_given 
    FROM public.points_history 
    WHERE user_id = NEW.user_id 
    AND action_type = 'reaction_given'
    AND reference_type = 'reaction'
    AND (description LIKE '%post:' || NEW.post_id::text || '%type:' || NEW.type || '%' 
         OR description = v_unique_key_given);
    
    -- SÓ ADICIONAR PONTOS PARA QUEM DEU A REAÇÃO SE NÃO EXISTE
    IF v_existing_reaction_given = 0 THEN
        -- Adicionar pontos para quem deu a reação com descrição única
        INSERT INTO public.points_history (
            user_id, 
            action_type, 
            points_earned, 
            reference_id, 
            reference_type,
            description,
            created_at
        ) VALUES (
            NEW.user_id,
            'reaction_given',
            2,
            NEW.id,
            'reaction',
            'post:' || NEW.post_id::text || ' type:' || NEW.type || ' unique:' || v_unique_key_given,
            NOW()
        );
        
        -- Atualizar total de pontos
        UPDATE public.user_points 
        SET total_points = total_points + 2,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
        
        -- Criar registro se não existir
        INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level)
        SELECT NEW.user_id, 2, 1, 98
        WHERE NOT EXISTS (SELECT 1 FROM public.user_points WHERE user_id = NEW.user_id);
    END IF;
    
    -- ADICIONAR PONTOS PARA QUEM RECEBEU A REAÇÃO
    IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
        -- Verificar se já existe pontuação para receber esta reação
        SELECT COUNT(*) INTO v_existing_reaction_received 
        FROM public.points_history 
        WHERE user_id = v_post_author 
        AND action_type = 'reaction_received'
        AND reference_type = 'reaction'
        AND (description LIKE '%post:' || NEW.post_id::text || '%type:' || NEW.type || '%from:' || NEW.user_id::text || '%'
             OR description = v_unique_key_received);
        
        IF v_existing_reaction_received = 0 THEN
            -- Adicionar pontos para quem recebeu a reação
            INSERT INTO public.points_history (
                user_id, 
                action_type, 
                points_earned, 
                reference_id, 
                reference_type,
                description,
                created_at
            ) VALUES (
                v_post_author,
                'reaction_received',
                3,
                NEW.id,
                'reaction',
                'post:' || NEW.post_id::text || ' type:' || NEW.type || ' from:' || NEW.user_id::text || ' unique:' || v_unique_key_received,
                NOW()
            );
            
            -- Atualizar total de pontos
            UPDATE public.user_points 
            SET total_points = total_points + 3,
                updated_at = NOW()
            WHERE user_id = v_post_author;
            
            -- Criar registro se não existir
            INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level)
            SELECT v_post_author, 3, 1, 97
            WHERE NOT EXISTS (SELECT 1 FROM public.user_points WHERE user_id = v_post_author);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Testar a nova abordagem
SELECT 'Nova abordagem implementada com chaves únicas na description' as status;

-- Verificar estrutura da tabela points_history
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'points_history' 
AND table_schema = 'public'
ORDER BY ordinal_position;

