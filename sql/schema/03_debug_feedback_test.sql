-- ============================================================================
-- DEBUG_FEEDBACK_TEST TABLE - Tabela de Debug/Teste
-- ============================================================================
-- Tabela temporária para debugging do sistema de feedbacks
-- Utilizada para testes e diagnósticos durante desenvolvimento
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.debug_feedback_test (
    -- Identificador sequencial
    id INTEGER PRIMARY KEY DEFAULT nextval('debug_feedback_test_id_seq'::regclass),
    
    -- Descrição do teste executado
    teste_executado TEXT,
    
    -- ID do feedback testado
    feedback_id TEXT,
    
    -- ID do post relacionado
    post_id TEXT,
    
    -- ID do autor do feedback
    author_id TEXT,
    
    -- ID do autor do post
    post_author_id TEXT,
    
    -- Username do usuário
    username_from TEXT,
    
    -- Se a notificação foi criada com sucesso
    notificacao_criada BOOLEAN,
    
    -- Mensagem de erro (se houver)
    erro TEXT,
    
    -- Timestamp do teste
    timestamp TIMESTAMP DEFAULT now()
);

-- ============================================================================
-- SEQUENCE PARA A TABELA
-- ============================================================================

-- Criar sequence se não existir
CREATE SEQUENCE IF NOT EXISTS debug_feedback_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Associar sequence à coluna id
ALTER SEQUENCE debug_feedback_test_id_seq OWNED BY public.debug_feedback_test.id;

-- ============================================================================
-- ÍNDICES DA TABELA DEBUG_FEEDBACK_TEST
-- ============================================================================

-- Índice para busca por timestamp (consultas de debug)
CREATE INDEX IF NOT EXISTS idx_debug_feedback_test_timestamp 
ON public.debug_feedback_test (timestamp DESC);

-- Índice para busca por feedback_id
CREATE INDEX IF NOT EXISTS idx_debug_feedback_test_feedback_id 
ON public.debug_feedback_test (feedback_id);

-- ============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.debug_feedback_test IS 
'Tabela temporária para debugging e testes do sistema de feedbacks.
Utilizada durante desenvolvimento para diagnosticar problemas.';

COMMENT ON COLUMN public.debug_feedback_test.id IS 'Identificador sequencial do teste';
COMMENT ON COLUMN public.debug_feedback_test.teste_executado IS 'Descrição do teste que foi executado';
COMMENT ON COLUMN public.debug_feedback_test.feedback_id IS 'ID do feedback sendo testado';
COMMENT ON COLUMN public.debug_feedback_test.post_id IS 'ID do post relacionado ao teste';
COMMENT ON COLUMN public.debug_feedback_test.author_id IS 'ID do autor do feedback';
COMMENT ON COLUMN public.debug_feedback_test.post_author_id IS 'ID do autor do post';
COMMENT ON COLUMN public.debug_feedback_test.username_from IS 'Username do usuário no teste';
COMMENT ON COLUMN public.debug_feedback_test.notificacao_criada IS 'Se a notificação foi criada com sucesso';
COMMENT ON COLUMN public.debug_feedback_test.erro IS 'Mensagem de erro capturada durante o teste';
COMMENT ON COLUMN public.debug_feedback_test.timestamp IS 'Timestamp de quando o teste foi executado';

-- ============================================================================
-- NOTAS SOBRE A TABELA DEBUG_FEEDBACK_TEST
-- ============================================================================
-- 
-- Estrutura Real Extraída:
-- - 10 campos para debugging completo
-- - INTEGER como chave primária com sequence
-- - Todos os campos opcionais (exceto id)
-- - Timestamp sem timezone (diferente das outras tabelas)
-- 
-- Propósito:
-- - Debugging do sistema de feedbacks
-- - Testes de notificações
-- - Diagnóstico de problemas
-- - Logs de desenvolvimento
-- 
-- Campos de Debug:
-- - teste_executado: Descrição do que foi testado
-- - feedback_id, post_id, author_id: IDs relacionados
-- - username_from: Username para testes
-- - notificacao_criada: Status de sucesso
-- - erro: Mensagens de erro capturadas
-- 
-- Uso Temporário:
-- - Esta tabela é para desenvolvimento/debug
-- - Pode ser removida em produção
-- - Não tem triggers ou relacionamentos
-- - Não afeta o sistema principal
-- 
-- Diferenças Estruturais:
-- - Usa INTEGER em vez de UUID
-- - Campos TEXT em vez de UUID para flexibilidade
-- - TIMESTAMP sem timezone
-- - Sequence manual em vez de gen_random_uuid()
-- 
-- Manutenção:
-- - Limpar periodicamente em desenvolvimento
-- - Remover em produção final
-- - Monitorar crescimento da tabela
-- - Usar para troubleshooting
-- 
-- ============================================================================

