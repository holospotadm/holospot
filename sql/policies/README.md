# 🔒 Policies RLS (Row Level Security)

Este diretório contém todas as políticas de Row Level Security do sistema HoloSpot, organizadas por funcionalidade e propósito.

## 📋 Estrutura dos Arquivos

### 01_public_read_policies.sql
**Políticas de Leitura Pública**
- Dados visíveis para todos os usuários
- Badges, levels, posts, comments, feedbacks, reactions
- Filosofia de transparência do HoloSpot
- 15 policies para leitura pública

### 02_user_ownership_policies.sql  
**Políticas de Propriedade do Usuário**
- Isolamento por usuário baseado em `auth.uid()`
- Usuários só acessam/modificam seus próprios dados
- Notificações, histórico, pontos, streaks privados
- 20 policies para controle de propriedade

### 03_system_operation_policies.sql
**Políticas de Operação do Sistema**
- Operações automáticas de triggers e funções
- Policies genéricas com `USING (true)`
- Diferenciação entre `public` e `authenticated`
- 25 policies para operações do sistema

## 📊 Estatísticas Gerais

- **Total de Policies:** 60
- **Tabelas com RLS:** 13 de 14
- **Tipos:** 100% PERMISSIVE (0 RESTRICTIVE)
- **Comandos:** SELECT (23), INSERT (18), UPDATE (8), DELETE (9)

## 🔐 Sistema de Segurança

### Princípios de Segurança
1. **Transparência Pública:** Holofotes e conquistas são públicos
2. **Isolamento Privado:** Dados pessoais isolados por usuário  
3. **Operação Automática:** Sistema pode operar sem restrições
4. **Autenticação Obrigatória:** Algumas operações requerem login

### Padrões de Policies

#### Leitura Pública
```sql
CREATE POLICY "nome_policy" ON tabela
    FOR SELECT TO public
    USING (true);
```

#### Propriedade do Usuário
```sql
CREATE POLICY "nome_policy" ON tabela
    FOR INSERT TO public
    WITH CHECK (auth.uid() = user_id);
```

#### Operação do Sistema
```sql
CREATE POLICY "nome_policy" ON tabela
    FOR INSERT TO public
    WITH CHECK (true);
```

## 🏗️ Deployment

### Ordem de Execução
1. **Habilitar RLS** nas tabelas primeiro
2. **01_public_read_policies.sql** - Leitura pública
3. **02_user_ownership_policies.sql** - Controle de usuário
4. **03_system_operation_policies.sql** - Operações do sistema

### Comandos de Deployment
```sql
-- Habilitar RLS em todas as tabelas
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
-- ... (repetir para todas as tabelas)

-- Executar arquivos de policies na ordem
\i 01_public_read_policies.sql
\i 02_user_ownership_policies.sql  
\i 03_system_operation_policies.sql
```

## 🛡️ Análise de Segurança

### Tabelas com RLS Habilitado
- ✅ badges, comments, feedbacks, follows, levels
- ✅ notifications, points_history, posts, profiles
- ✅ reactions, user_badges, user_points, user_streaks
- ❌ debug_feedback_test (sem RLS - tabela de debug)

### Cobertura de Comandos
- **SELECT:** Todas as tabelas têm policies
- **INSERT:** Maioria das tabelas operacionais
- **UPDATE:** Tabelas que permitem edição
- **DELETE:** Tabelas que permitem remoção

### Policies Redundantes
Algumas tabelas têm múltiplas policies para o mesmo comando:
- **posts:** 2 policies SELECT, 3 policies INSERT
- **comments:** 2 policies SELECT, 2 policies INSERT  
- **feedbacks:** 2 policies SELECT, 2 policies INSERT
- **reactions:** 2 policies SELECT, 2 policies INSERT

**Recomendação:** Consolidar policies duplicadas para simplificar manutenção.

## 🔍 Verificação e Testes

### Comandos de Verificação
```sql
-- Verificar status de RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Contar policies por tabela
SELECT tablename, COUNT(*) as total_policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename;

-- Verificar policies por comando
SELECT cmd, COUNT(*) as total
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY cmd;
```

### Testes de Segurança
1. **Teste de Isolamento:** Usuário A não pode ver dados de usuário B
2. **Teste de Leitura Pública:** Dados públicos visíveis para todos
3. **Teste de Sistema:** Triggers funcionam corretamente
4. **Teste de Autenticação:** Operações requerem login quando necessário

## 📚 Documentação Adicional

### Conceitos de RLS
- **PERMISSIVE:** Permite acesso se condição for verdadeira
- **RESTRICTIVE:** Nega acesso se condição for verdadeira
- **USING:** Condição para operações existentes (SELECT, UPDATE, DELETE)
- **WITH CHECK:** Condição para dados novos (INSERT, UPDATE)

### Funções do Supabase
- **auth.uid():** ID do usuário autenticado
- **auth.role():** Role do usuário atual
- **auth.jwt():** Token JWT completo

### Roles Utilizadas
- **public:** Acesso geral (sistema + usuários)
- **authenticated:** Apenas usuários logados
- **anon:** Usuários não autenticados (não usado)

## 🔧 Manutenção

### Monitoramento
- Verificar performance de policies complexas
- Monitorar logs de acesso negado
- Analisar uso de policies redundantes

### Otimização
- Consolidar policies duplicadas
- Simplificar condições complexas
- Adicionar índices para policies com JOINs

### Atualizações
- Testar mudanças em ambiente de desenvolvimento
- Validar impacto em triggers e funções
- Documentar alterações de segurança

---

**Última Atualização:** Setembro 2025  
**Versão:** 1.0.0  
**Status:** Produção

