-- =====================================================
-- DEBUG INTELIGENTE: INVESTIGAR PROBLEMA COM reference_id
-- =====================================================

-- 1. VERIFICAR SE reference_id CORRESPONDE A IDs REAIS DE REAÇÕES
SELECT 
    'PROBLEMA CRÍTICO: reference_id não existe na tabela reactions' as problema,
    COUNT(*) as total_problemas
FROM public.points_history ph
LEFT JOIN public.reactions r ON ph.reference_id = r.id
WHERE ph.reference_type = 'reaction'
AND r.id IS NULL;

-- 2. VERIFICAR REAÇÕES QUE GERARAM PONTOS MÚLTIPLOS
WITH reaction_points AS (
    SELECT 
        r.user_id,
        r.post_id,
        r.type,
        COUNT(ph.id) as total_points_entries,
        STRING_AGG(ph.id::text, ', ') as points_ids
    FROM public.reactions r
    JOIN public.points_history ph ON r.id = ph.reference_id
    WHERE ph.action_type = 'reaction_given'
    GROUP BY r.user_id, r.post_id, r.type
    HAVING COUNT(ph.id) > 1
)
SELECT 
    'DUPLICATAS ENCONTRADAS' as status,
    user_id,
    post_id,
    type,
    total_points_entries,
    points_ids
FROM reaction_points
ORDER BY total_points_entries DESC;

-- 3. TESTAR A LÓGICA DO TRIGGER COM DADOS REAIS
WITH test_data AS (
    SELECT DISTINCT 
        r.user_id,
        r.post_id,
        r.type
    FROM public.reactions r
    LIMIT 5
)
SELECT 
    td.user_id,
    td.post_id,
    td.type,
    COUNT(ph.id) as pontos_ja_dados,
    CASE 
        WHEN COUNT(ph.id) = 0 THEN 'DEVERIA DAR PONTOS'
        WHEN COUNT(ph.id) = 1 THEN 'CORRETO - JÁ DEU PONTOS'
        ELSE 'PROBLEMA - PONTOS DUPLICADOS'
    END as status
FROM test_data td
LEFT JOIN public.points_history ph ON (
    ph.user_id = td.user_id 
    AND ph.action_type = 'reaction_given'
    AND ph.reference_type = 'reaction'
    AND EXISTS (
        SELECT 1 FROM public.reactions r 
        WHERE r.id = ph.reference_id 
        AND r.post_id = td.post_id 
        AND r.type = td.type
        AND r.user_id = td.user_id
    )
)
GROUP BY td.user_id, td.post_id, td.type
ORDER BY pontos_ja_dados DESC;

-- 4. VERIFICAR COMO add_points_to_user ESTÁ SALVANDO
SELECT 
    ph.reference_id,
    ph.reference_type,
    ph.action_type,
    ph.points_earned,
    r.id as reaction_exists,
    CASE 
        WHEN r.id IS NULL THEN 'REFERENCE_ID INVÁLIDO'
        ELSE 'REFERENCE_ID VÁLIDO'
    END as validation
FROM public.points_history ph
LEFT JOIN public.reactions r ON ph.reference_id = r.id
WHERE ph.reference_type = 'reaction'
AND ph.created_at > NOW() - INTERVAL '1 day'
ORDER BY ph.created_at DESC
LIMIT 10;

-- 5. ENCONTRAR O PROBLEMA REAL
SELECT 
    'DIAGNÓSTICO FINAL' as resultado,
    CASE 
        WHEN invalid_refs.count > 0 THEN 'PROBLEMA: reference_id inválidos encontrados'
        WHEN duplicates.count > 0 THEN 'PROBLEMA: Pontos duplicados encontrados'
        ELSE 'SISTEMA FUNCIONANDO CORRETAMENTE'
    END as diagnostico
FROM 
    (SELECT COUNT(*) as count FROM public.points_history ph 
     LEFT JOIN public.reactions r ON ph.reference_id = r.id 
     WHERE ph.reference_type = 'reaction' AND r.id IS NULL) invalid_refs,
    (SELECT COUNT(*) as count FROM (
        SELECT r.user_id, r.post_id, r.type, COUNT(ph.id) as cnt
        FROM public.reactions r
        JOIN public.points_history ph ON r.id = ph.reference_id
        WHERE ph.action_type = 'reaction_given'
        GROUP BY r.user_id, r.post_id, r.type
        HAVING COUNT(ph.id) > 1
    ) x) duplicates;

