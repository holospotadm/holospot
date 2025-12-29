-- ============================================================================
-- FUNÇÃO: group_reaction_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.group_reaction_notifications(p_user_id uuid, p_hours_window integer DEFAULT 2)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    notification_group RECORD;
    grouped_count INTEGER := 0;
BEGIN
    -- Agrupar reações por from_user_id nas últimas X horas
    FOR notification_group IN
        SELECT 
            from_user_id,
            array_agg(DISTINCT 
                CASE 
                    WHEN message LIKE '%❤️%' THEN '❤️'
                    WHEN message LIKE '%✨%' THEN '✨'
                    WHEN message LIKE '%🙏%' THEN '🙏'
                    ELSE '👍'
                END
            ) as reactions,
            COUNT(*) as total_count,
            MAX(created_at) as last_created,
            array_agg(id) as notification_ids
        FROM public.notifications 
        WHERE user_id = p_user_id 
        AND type = 'reaction'
        AND created_at >= NOW() - (p_hours_window || ' hours')::INTERVAL
        AND group_key IS NULL
        GROUP BY from_user_id
        HAVING COUNT(*) > 1
    LOOP
        -- Criar notificação agrupada
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            group_key, group_count, group_data, 
            priority, created_at
        ) VALUES (
            p_user_id,
            notification_group.from_user_id,
            'reaction_grouped',
            (SELECT username FROM public.profiles WHERE id = notification_group.from_user_id) || 
            ' reagiu (' || array_to_string(notification_group.reactions, '') || ') aos seus posts',
            'reaction_' || notification_group.from_user_id::text,
            notification_group.total_count,
            jsonb_build_object(
                'reactions', notification_group.reactions,
                'original_count', notification_group.total_count,
                'original_ids', notification_group.notification_ids
            ),
            2, -- Prioridade média
            notification_group.last_created
        );
        
        -- Marcar originais como agrupadas
        UPDATE public.notifications 
        SET group_key = 'reaction_' || notification_group.from_user_id::text
        WHERE id = ANY(notification_group.notification_ids);
        
        grouped_count := grouped_count + 1;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$

