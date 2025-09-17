-- ============================================================================
-- POLÍTICAS DE SEGURANÇA (RLS) - HOLOSPOT
-- ============================================================================
-- Row Level Security policies extraídas do banco
-- ============================================================================

-- Para listar todas as políticas ativas, execute:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies 
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- Para ver políticas específicas de uma tabela:
-- \d+ nome_da_tabela

-- Nenhuma política RLS explícita encontrada na extração
-- Execute o comando acima no Supabase para listar todas as políticas
