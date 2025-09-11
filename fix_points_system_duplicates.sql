-- =====================================================
-- CORREÇÃO: SISTEMA DE PONTUAÇÃO - REAÇÕES DUPLICADAS + HOLOFOTES
-- =====================================================

-- 1. CORRIGIR TRIGGER DE REAÇÃO PARA EVITAR DUPLICATAS
CREATE OR REPLACE FUNCTION trigger_reaction_given()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
    v_existing_points INTEGER;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = NEW.post_id;
    
    -- VERIFICAR SE JÁ EXISTE PONTUAÇÃO PARA ESTA REAÇÃO ESPECÍFICA
    SELECT COUNT(*) INTO v_existing_points 
    FROM public.points_history 
    WHERE user_id = NEW.user_id 
    AND action_type = 'reaction_given'
    AND reference_id = NEW.id
    AND reference_type = 'reaction';
    
    -- SÓ ADICIONAR PONTOS SE NÃO EXISTE HISTÓRICO ANTERIOR
    IF v_existing_points = 0 THEN
        -- Adicionar pontos para quem deu a reação
        PERFORM add_points_to_user(NEW.user_id, 'reaction_given', 2, NEW.id, 'reaction');
        
        -- Adicionar pontos para quem recebeu a reação (autor do post)
        IF v_post_author IS NOT NULL AND v_post_author != NEW.user_id THEN
            -- Verificar se já existe pontuação para receber esta reação
            SELECT COUNT(*) INTO v_existing_points 
            FROM public.points_history 
            WHERE user_id = v_post_author 
            AND action_type = 'reaction_received'
            AND reference_id = NEW.id
            AND reference_type = 'reaction';
            
            IF v_existing_points = 0 THEN
                PERFORM add_points_to_user(v_post_author, 'reaction_received', 3, NEW.id, 'reaction');
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. CORRIGIR TRIGGER DE POST PARA HOLOFOTES
CREATE OR REPLACE FUNCTION trigger_post_created()
RETURNS TRIGGER AS $$
DECLARE
    v_existing_points INTEGER;
BEGIN
    -- Verificar se já existe pontuação para criação deste post
    SELECT COUNT(*) INTO v_existing_points 
    FROM public.points_history 
    WHERE user_id = NEW.user_id 
    AND action_type = 'post_created'
    AND reference_id = NEW.id
    AND reference_type = 'post';
    
    -- SÓ ADICIONAR PONTOS SE NÃO EXISTE HISTÓRICO ANTERIOR
    IF v_existing_points = 0 THEN
        -- Adicionar pontos para quem criou o post
        PERFORM add_points_to_user(NEW.user_id, 'post_created', 10, NEW.id, 'post');
    END IF;
    
    -- CORRIGIDO: Se mencionou alguém, dar pontos extras (HOLOFOTE)
    IF NEW.mentioned_user_id IS NOT NULL THEN
        -- Verificar se já existe pontuação para holofote deste post
        SELECT COUNT(*) INTO v_existing_points 
        FROM public.points_history 
        WHERE user_id = NEW.user_id 
        AND action_type = 'holofote_given'
        AND reference_id = NEW.id
        AND reference_type = 'post';
        
        IF v_existing_points = 0 THEN
            PERFORM add_points_to_user(NEW.user_id, 'holofote_given', 20, NEW.id, 'post');
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. TRIGGER PARA REMOVER PONTOS QUANDO REAÇÃO É DELETADA
CREATE OR REPLACE FUNCTION trigger_reaction_deleted()
RETURNS TRIGGER AS $$
DECLARE
    v_post_author UUID;
BEGIN
    -- Obter autor do post
    SELECT user_id INTO v_post_author FROM public.posts WHERE id = OLD.post_id;
    
    -- Remover pontos de quem deu a reação (se existir no histórico)
    DELETE FROM public.points_history 
    WHERE user_id = OLD.user_id 
    AND action_type = 'reaction_given'
    AND reference_id = OLD.id
    AND reference_type = 'reaction';
    
    -- Remover pontos de quem recebeu a reação (se existir no histórico)
    IF v_post_author IS NOT NULL AND v_post_author != OLD.user_id THEN
        DELETE FROM public.points_history 
        WHERE user_id = v_post_author 
        AND action_type = 'reaction_received'
        AND reference_id = OLD.id
        AND reference_type = 'reaction';
    END IF;
    
    -- Recalcular pontos totais para ambos os usuários
    PERFORM recalculate_user_points(OLD.user_id);
    IF v_post_author IS NOT NULL AND v_post_author != OLD.user_id THEN
        PERFORM recalculate_user_points(v_post_author);
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 4. FUNÇÃO PARA RECALCULAR PONTOS TOTAIS
CREATE OR REPLACE FUNCTION recalculate_user_points(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_points INTEGER;
    v_new_level INTEGER;
BEGIN
    -- Calcular total de pontos do histórico
    SELECT COALESCE(SUM(points_earned), 0) INTO v_total_points
    FROM public.points_history 
    WHERE user_id = p_user_id;
    
    -- Calcular novo nível
    v_new_level := calculate_user_level(v_total_points);
    
    -- Atualizar tabela user_points
    UPDATE public.user_points 
    SET 
        total_points = v_total_points,
        level_id = v_new_level,
        points_to_next_level = CASE 
            WHEN v_new_level < 10 THEN (v_new_level * 100) - v_total_points
            ELSE 0
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Se não existe registro, criar
    IF NOT FOUND THEN
        INSERT INTO public.user_points (user_id, total_points, level_id, points_to_next_level)
        VALUES (p_user_id, v_total_points, v_new_level, 
                CASE WHEN v_new_level < 10 THEN (v_new_level * 100) - v_total_points ELSE 0 END);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. CRIAR TRIGGER PARA DELEÇÃO DE REAÇÕES (se não existir)
DROP TRIGGER IF EXISTS trigger_reaction_deleted_points ON public.reactions;
CREATE TRIGGER trigger_reaction_deleted_points
    BEFORE DELETE ON public.reactions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_reaction_deleted();

-- Verificar triggers ativos
SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    'Trigger corrigido/criado' as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('posts', 'reactions')
AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

-- Testar correções
SELECT 'Sistema de pontuação corrigido:' as resultado,
       '1. Reações não duplicam pontos' as correcao_1,
       '2. Holofotes contabilizam +20 pts' as correcao_2,
       '3. Remoção de reações remove pontos' as correcao_3;

