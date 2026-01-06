-- ============================================================================
-- FUNÇÃO: check_memorias_vivas_badges
-- Descrição: Verifica e concede badges relacionados ao Memórias Vivas
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_memorias_vivas_badges()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    memorias_vivas_id UUID;
    user_to_check UUID;
    posts_count INTEGER;
    reactions_received INTEGER;
    reactions_given INTEGER;
    comments_count INTEGER;
    interactions_count INTEGER;
    badge_record RECORD;
BEGIN
    -- Buscar ID do Memórias Vivas
    SELECT get_memorias_vivas_community_id() INTO memorias_vivas_id;
    
    -- Se não existe Memórias Vivas, sair
    IF memorias_vivas_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Determinar qual usuário verificar baseado na tabela
    IF TG_TABLE_NAME = 'posts' THEN
        -- Verificar se o post é do Memórias Vivas
        IF NEW.community_id != memorias_vivas_id THEN
            RETURN NEW;
        END IF;
        user_to_check := NEW.user_id;
        
        -- Contar posts do usuário no Memórias Vivas
        posts_count := count_user_memorias_vivas_posts(user_to_check);
        
        -- Verificar badges de posts
        FOR badge_record IN 
            SELECT id, condition_value 
            FROM public.badges 
            WHERE category = 'memorias_vivas' 
            AND condition_type = 'memorias_vivas_posts'
        LOOP
            IF posts_count >= badge_record.condition_value THEN
                INSERT INTO public.user_badges (user_id, badge_id)
                VALUES (user_to_check, badge_record.id)
                ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
        
    ELSIF TG_TABLE_NAME = 'reactions' THEN
        -- Buscar o post para verificar se é do Memórias Vivas
        DECLARE
            post_community_id UUID;
            post_owner_id UUID;
        BEGIN
            SELECT community_id, user_id INTO post_community_id, post_owner_id
            FROM public.posts WHERE id = NEW.post_id;
            
            IF post_community_id != memorias_vivas_id THEN
                RETURN NEW;
            END IF;
            
            -- Verificar badges para quem DEU a reação
            reactions_given := count_user_memorias_vivas_reactions_given(NEW.user_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_reactions_given'
            LOOP
                IF reactions_given >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (NEW.user_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badges para quem RECEBEU a reação (dono do post)
            reactions_received := count_user_memorias_vivas_reactions_received(post_owner_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_reactions_received'
            LOOP
                IF reactions_received >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (post_owner_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badge de interações (reações + comentários)
            interactions_count := reactions_given + count_user_memorias_vivas_comments(NEW.user_id);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_interactions'
            LOOP
                IF interactions_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (NEW.user_id, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END;
        
    ELSIF TG_TABLE_NAME = 'comments' THEN
        -- Buscar o post para verificar se é do Memórias Vivas
        DECLARE
            post_community_id UUID;
        BEGIN
            SELECT community_id INTO post_community_id
            FROM public.posts WHERE id = NEW.post_id;
            
            IF post_community_id != memorias_vivas_id THEN
                RETURN NEW;
            END IF;
            
            user_to_check := NEW.user_id;
            
            -- Contar comentários do usuário no Memórias Vivas
            comments_count := count_user_memorias_vivas_comments(user_to_check);
            
            -- Verificar badges de comentários
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_comments'
            LOOP
                IF comments_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (user_to_check, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
            
            -- Verificar badge de interações
            interactions_count := comments_count + count_user_memorias_vivas_reactions_given(user_to_check);
            
            FOR badge_record IN 
                SELECT id, condition_value 
                FROM public.badges 
                WHERE category = 'memorias_vivas' 
                AND condition_type = 'memorias_vivas_interactions'
            LOOP
                IF interactions_count >= badge_record.condition_value THEN
                    INSERT INTO public.user_badges (user_id, badge_id)
                    VALUES (user_to_check, badge_record.id)
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.check_memorias_vivas_badges() IS 'Verifica e concede badges relacionados ao Memórias Vivas';
