-- ============================================================================
-- FUNÇÃO: auto_group_recent_notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_group_recent_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    grouped_count INTEGER := 0;
    user_record RECORD;
    reaction_group RECORD;
BEGIN
    -- Para cada usuário com notificações de reação recentes
    FOR user_record IN 
        SELECT DISTINCT user_id 
        FROM public.notifications 
        WHERE type = 'reaction'
        AND created_at >= NOW() - INTERVAL '30 minutes'
        AND group_key IS NULL
    LOOP
        -- Verificar se tem múltiplas reações do mesmo usuário
        FOR reaction_group IN
            SELECT 
                from_user_id,
                COUNT(*) as reaction_count,
                array_agg(DISTINCT 
                    CASE 
                        WHEN message LIKE '%❤️%' THEN '❤️'
                        WHEN message LIKE '%✨%' THEN '✨'
                        WHEN message LIKE '%🙏%' THEN '🙏'
                        ELSE '👍'
                    END
                ) as emojis,
                array_agg(id) as notification_ids,
                MAX(created_at) as last_created
            FROM public.notifications 
            WHERE user_id = user_record.user_id
            AND type = 'reaction'
            AND created_at >= NOW() - INTERVAL '30 minutes'
            AND group_key IS NULL
            GROUP BY from_user_id
            HAVING COUNT(*) >= 2
        LOOP
            -- Criar notificação agrupada
            INSERT INTO public.notifications (
                user_id, from_user_id, type, message, 
                group_key, group_count, priority, created_at
            ) VALUES (
                user_record.user_id,
                reaction_group.from_user_id,
                'reaction_grouped',
                (SELECT username FROM public.profiles WHERE id = reaction_group.from_user_id) || 
                ' reagiu (' || array_to_string(reaction_group.emojis, '') || ') aos seus posts',
                'group_' || reaction_group.from_user_id::text || '_' || user_record.user_id::text,
                reaction_group.reaction_count,
                2,
                reaction_group.last_created
            );
            
            -- Marcar originais como agrupadas (não deletar, só marcar)
            UPDATE public.notifications 
            SET group_key = 'group_' || reaction_group.from_user_id::text || '_' || user_record.user_id::text
            WHERE id = ANY(reaction_group.notification_ids);
            
            grouped_count := grouped_count + 1;
        END LOOP;
    END LOOP;
    
    RETURN grouped_count;
END;
$function$

