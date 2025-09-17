-- ============================================================================
-- FIX: Corrigir único registro órfão em feedbacks
-- ============================================================================
-- Data: 2025-09-16
-- Problema: 1 registro com author_id que não existe em profiles
-- Solução: Deletar o registro específico e aplicar FK
-- ============================================================================

-- 1. Verificar o registro problemático
-- ============================================================================

SELECT 'REGISTRO PROBLEMÁTICO:' as info;
SELECT 
    id,
    author_id,
    post_id,
    mentioned_user_id,
    feedback_text,
    created_at
FROM feedbacks 
WHERE author_id = '3157524f-072d-4ee8-a22e-861dcbd05b5f';

-- 2. Fazer backup do registro antes de deletar
-- ============================================================================

CREATE TEMP TABLE backup_orphan_feedback AS
SELECT * FROM feedbacks 
WHERE author_id = '3157524f-072d-4ee8-a22e-861dcbd05b5f';

SELECT 'BACKUP CRIADO:' as info;
SELECT COUNT(*) as registros_backup FROM backup_orphan_feedback;

-- 3. Deletar o registro órfão
-- ============================================================================

DELETE FROM feedbacks 
WHERE author_id = '3157524f-072d-4ee8-a22e-861dcbd05b5f';

SELECT 'REGISTRO DELETADO' as info;

-- 4. Aplicar a FK que estava falhando
-- ============================================================================

ALTER TABLE feedbacks 
ADD CONSTRAINT fk_feedbacks_author 
FOREIGN KEY (author_id) REFERENCES profiles(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

SELECT 'FK CRIADA COM SUCESSO!' as info;

-- 5. Verificação final
-- ============================================================================

-- Verificar se a FK foi criada
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS references_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
    AND tc.constraint_name = 'fk_feedbacks_author';

-- Verificar integridade final
SELECT 
    'VERIFICAÇÃO FINAL:' as info,
    COUNT(*) as total_feedbacks,
    COUNT(CASE WHEN p.id IS NOT NULL THEN 1 END) as author_ids_validos,
    COUNT(CASE WHEN p.id IS NULL THEN 1 END) as author_ids_invalidos
FROM feedbacks f
LEFT JOIN profiles p ON f.author_id = p.id
WHERE f.author_id IS NOT NULL;

-- ============================================================================
-- RECUPERAÇÃO (se necessário)
-- ============================================================================
/*
-- Para recuperar o registro deletado (se necessário):
INSERT INTO feedbacks SELECT * FROM backup_orphan_feedback;

-- Para remover a FK (se necessário):
ALTER TABLE feedbacks DROP CONSTRAINT fk_feedbacks_author;
*/

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

SELECT '✅ CORREÇÃO CONCLUÍDA: FK feedbacks.author_id criada com sucesso!' as resultado;

