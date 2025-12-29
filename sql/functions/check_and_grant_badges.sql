-- ============================================================================
-- FUNÇÃO: check_and_grant_badges
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_and_grant_badges(p_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    badge_record RECORD;
    current_count INTEGER;
    badges_granted INTEGER := 0;
    result_text TEXT := '';
BEGIN
    -- Buscar todos os badges que o usuário ainda não tem
    FOR badge_record IN 
        SELECT b.* 
        FROM public.badges b
        WHERE NOT EXISTS (
            SELECT 1 FROM public.user_badges ub 
            WHERE ub.user_id = p_user_id 
            AND ub.badge_id = b.id
        )
    LOOP
        current_count := 0;
        
        -- Calcular progresso atual baseado no tipo de condição
        CASE badge_record.condition_type
            WHEN 'posts_count' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id;
                
            WHEN 'reactions_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.reactions 
                WHERE user_id = p_user_id;
                
            WHEN 'comments_written' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.comments 
                WHERE user_id = p_user_id;
                
            WHEN 'feedbacks_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.feedbacks 
                WHERE mentioned_user_id = p_user_id;
                
            WHEN 'holofotes_given' THEN
                SELECT COUNT(*) INTO current_count
                FROM public.posts 
                WHERE user_id = p_user_id 
                AND mentioned_user_id IS NOT NULL;
                
            WHEN 'total_points' THEN
                SELECT COALESCE(total_points, 0) INTO current_count
                FROM public.user_points 
                WHERE user_id = p_user_id;
                
            ELSE
                current_count := 0;
        END CASE;
        
        -- Se atingiu a condição, conceder o badge
        IF current_count >= badge_record.condition_value THEN
            INSERT INTO public.user_badges (user_id, badge_id, earned_at)
            VALUES (p_user_id, badge_record.id, NOW())
            ON CONFLICT (user_id, badge_id) DO NOTHING;
            
            -- Verificar se foi realmente inserido (não era duplicata)
            IF FOUND THEN
                badges_granted := badges_granted + 1;
                result_text := result_text || 'Badge "' || badge_record.name || '" concedido! ';
                
                RAISE NOTICE 'Badge % concedido para usuário %', badge_record.name, p_user_id;
            END IF;
        END IF;
    END LOOP;
    
    IF badges_granted > 0 THEN
        RETURN 'Concedidos ' || badges_granted || ' badges: ' || result_text;
    ELSE
        RETURN 'Nenhum badge novo concedido';
    END IF;
END;
$function$

