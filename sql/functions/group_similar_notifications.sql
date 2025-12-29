-- ============================================================================
-- FUNÇÃO: group_similar_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.group_similar_notifications()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    grouped_count INTEGER := 0;
    notification_group RECORD;
BEGIN
    -- Para cada usuário que recebeu múltiplas notificações de reação
    FOR notification_group IN
        SELECT 
            user_id,
            from_user_id,
            COUNT(*) as notification_count,
            array_agg(DISTINCT 
                CASE 
                    WHEN message LIKE '%❤️%' THEN '❤️'
                    WHEN message LIKE '%✨%' THEN '✨'
                    WHEN message LIKE '%🙏%' THEN '🙏'
                    ELSE '👍'
                END
            ) as emojis,
            array_agg(id ORDER BY created_at) as notification_ids,
            MAX(created_at) as last_created,
            (SELECT username FROM public.profiles WHERE id = from_user_id) as from_username
        FROM public.notifications 
        WHERE type = 'reaction'
        AND created_at >= NOW() - INTERVAL '30 minutes'
        AND group_key IS NULL
        GROUP BY user_id, from_user_id
        HAVING COUNT(*) >= 2
    LOOP
        -- Criar notificação agrupada
        INSERT INTO public.notifications (
            user_id, from_user_id, type, message, 
            group_key, group_count, priority, created_at
        ) VALUES (
            notification_group.user_id,
            notification_group.from_user_id,
            'reaction_grouped',
            notification_group.from_username || ' reagiu (' || array_to_string(notification_group.emojis, '') || ') aos seus posts',
            'group_' || notification_group.from_user_id::text || '_' || notification_group.user_id::text || '_' || EXTRACT(epoch FROM NOW())::text,
            notification_group.notification_count,
            2,
            notification_group.last_created
        );
        
        -- Marcar originais como agrupadas (não deletar, apenas marcar)
        UPDATE public.notifications 
        SET group_key = 'group_' || notification_group.from_user_id::text || '_' || notification_group.user_id::text || '_' || EXTRACT(epoch FROM NOW())::text
        WHERE id = ANY(notification_group.notification_ids);
        
        grouped_count := grouped_count + 1;
        
        RAISE NOTICE 'AGRUPAMENTO: % reações de % agrupadas para %', 
            notification_group.notification_count, notification_group.from_username, notification_group.user_id;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$

