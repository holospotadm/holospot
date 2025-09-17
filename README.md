# 🌟 HoloSpot

Sistema de rede social com gamificação e notificações inteligentes.

## 🤖 **GUIA PARA NOVA IA - METODOLOGIA COMPROVADA**

Se você é uma nova IA assumindo este projeto, **este guia contém a metodologia exata** que foi usada com sucesso para resolver problemas complexos e implementar funcionalidades avançadas.

### 📊 **Status Atual do Projeto**

**Versão:** v6.1-enhanced  
**Status:** ✅ 100% Documentado e Organizado  
**Última atualização:** 2025-09-17  
**Metodologia:** ✅ Comprovada e Testada

**IMPORTANTE:** Este projeto está **100% funcional** e **completamente documentado**. Não refaça nada do zero - tudo está organizado e pronto para uso.

## 🚨 **METODOLOGIA COMPROVADA - SIGA EXATAMENTE!**

### **🔍 1. PRINCÍPIO FUNDAMENTAL: INVESTIGAÇÃO ANTES DE AÇÃO**

**NUNCA assuma nada. SEMPRE investigue primeiro.**

#### **Processo de Investigação Obrigatório:**
```shell
# ORDEM OBRIGATÓRIA PARA QUALQUER PROBLEMA:
1. 🔍 Reproduzir o erro exato (copiar mensagem completa)
2. 🔍 Identificar tabelas/funções envolvidas
3. 🔍 Extrair estado atual do banco (usar scripts abaixo)
4. 🔍 Verificar arquivos no GitHub
5. 🔍 Analisar logs e stack traces
6. 🔍 Identificar causa raiz ANTES de propor solução
```

#### **Scripts de Investigação Essenciais:**
```sql
-- 1. VERIFICAR FUNÇÕES EXISTENTES
SELECT proname, prosrc FROM pg_proc 
WHERE proname ILIKE '%nome_suspeito%';

-- 2. VERIFICAR TRIGGERS ATIVOS
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE table_name = 'tabela_problema';

-- 3. VERIFICAR ESTRUTURA DE TABELA
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tabela_problema' 
ORDER BY ordinal_position;

-- 4. VERIFICAR POLÍTICAS RLS
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'tabela_problema';
```

### **🔧 2. METODOLOGIA DE RESOLUÇÃO DE PROBLEMAS**

#### **Processo Comprovado para Erros SQL:**

**EXEMPLO REAL:** Erro `record "new" has no field "user_id"`

```shell
# PASSO 1: INVESTIGAÇÃO PROFUNDA
1. 🔍 Buscar TODAS as ocorrências de "NEW.user_id" no código
   grep -n "NEW\.user_id" /path/to/sql/functions/ALL_FUNCTIONS.sql

2. 🔍 Verificar estrutura da tabela problemática
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'feedbacks';

3. 🔍 Identificar triggers que executam na tabela
   SELECT trigger_name, action_statement FROM information_schema.triggers 
   WHERE table_name = 'feedbacks';

# PASSO 2: ANÁLISE DE CAUSA RAIZ
4. 🔍 Mapear fluxo de execução:
   INSERT feedbacks → trigger X → função Y → erro em campo Z

5. 🔍 Identificar TODAS as funções afetadas (não apenas a óbvia)

# PASSO 3: CORREÇÃO SISTEMÁTICA
6. ✅ Corrigir TODAS as ocorrências (não apenas uma)
7. ✅ Testar lógica condicional se necessário
8. ✅ Adicionar SECURITY DEFINER se for problema de RLS
```

#### **Processo Comprovado para Erros RLS:**

**EXEMPLO REAL:** Erro `new row violates row-level security policy`

```shell
# DIAGNÓSTICO RLS:
1. 🔍 Identificar qual função está tentando INSERT/UPDATE
2. 🔍 Verificar se função tem SECURITY DEFINER
3. 🔍 Verificar políticas da tabela afetada
4. 🔍 Identificar se é problema de privilégios ou lógica

# CORREÇÃO RLS:
1. ✅ Adicionar SECURITY DEFINER à função
2. ✅ Adicionar SET search_path TO 'public' para segurança
3. ✅ Verificar se políticas permitem operação do sistema
```

### **📁 3. WORKFLOW OBRIGATÓRIO PARA ALTERAÇÕES**

#### **Ordem EXATA que SEMPRE funciona:**

```shell
# NUNCA INVERTER ESTA ORDEM:
1. 📝 Investigar problema completamente
2. 📝 Modificar arquivos SQL/HTML no GitHub
3. 💾 git add .
4. 💾 git commit -m "fix: Descrição específica do problema resolvido"
5. 💾 git push origin main
6. 📤 Fornecer script SQL pronto para usuário executar
7. ✅ Aguardar confirmação de execução
8. 📋 Documentar se necessário
```

#### **Exemplo de Commit Message Eficaz:**
```shell
# ❌ RUIM:
git commit -m "fix bug"

# ✅ BOM:
git commit -m "fix: Corrigir erro NEW.user_id em feedbacks

PROBLEMA: record 'new' has no field 'user_id'
CAUSA: update_user_streak_trigger() usava NEW.user_id em todas tabelas
SOLUÇÃO: Lógica condicional por tabela (feedbacks usa NEW.author_id)
AFETADO: update_user_streak_trigger, notify_feedback_smart
RESOLVE: Erro em feedbacks que bloqueava sistema de streaks"
```

### **🔍 4. PADRÕES DE DEBUGGING COMPROVADOS**

#### **Para Problemas de Frontend:**
```javascript
// SEMPRE adicionar logs detalhados:
console.log('🔍 Função X iniciada com parâmetros:', params);
console.log('📊 Estado antes da operação:', currentState);
console.log('⚠️ Erro capturado:', error);
console.log('✅ Resultado final:', result);
```

#### **Para Problemas de Backend:**
```sql
-- SEMPRE adicionar RAISE NOTICE para debug:
RAISE NOTICE '🔍 Função % iniciada para user %', TG_NAME, NEW.user_id;
RAISE NOTICE '📊 Dados encontrados: %', variable_name;
RAISE NOTICE '⚠️ Condição não atendida: %', condition_check;
```

### **🛡️ 5. PREVENÇÃO DE ERROS COMUNS**

#### **Checklist Antes de Qualquer Alteração:**
- [ ] ✅ Extraí o estado atual do banco?
- [ ] ✅ Verifiquei TODAS as funções relacionadas?
- [ ] ✅ Testei a lógica em diferentes cenários?
- [ ] ✅ Considerei impactos em outras funcionalidades?
- [ ] ✅ Adicionei logs para debug futuro?
- [ ] ✅ Documentei a mudança adequadamente?

#### **Armadilhas Fatais a Evitar:**
- ❌ **Assumir que campo existe** sem verificar schema
- ❌ **Corrigir apenas uma ocorrência** de um problema sistêmico
- ❌ **Ignorar triggers** que podem estar causando efeitos colaterais
- ❌ **Esquecer SECURITY DEFINER** em funções que fazem operações de sistema
- ❌ **Não testar com dados reais** antes de commitar

## 🎯 **ONDE ENCONTRAR CADA COISA**

### 🏗️ **ESTRUTURA COMPLETA DO PROJETO**

```
holospot/
├── index.html              # 📱 Frontend principal (HTML + CSS + JavaScript)
├── README.md               # 📖 Este arquivo (instruções completas)
└── sql/                    # 🗄️ Estrutura completa do banco de dados
    ├── functions/          # 🔧 Funções PostgreSQL (116 funções)
    │   ├── ALL_FUNCTIONS.sql
    │   └── README.md
    ├── triggers/           # ⚡ Triggers PostgreSQL (29 triggers)
    │   ├── ALL_TRIGGERS.sql
    │   └── README.md
    ├── schema/             # 📋 Definições das tabelas (14 tabelas)
    │   ├── 01_badges.sql até 14_user_streaks.sql
    │   └── README.md
    ├── data/               # 🎮 Dados iniciais (badges, levels)
    │   ├── 01_badges_initial_data.sql
    │   ├── 02_levels_initial_data.sql
    │   └── README.md
    ├── policies/           # 🔒 Políticas RLS de segurança
    │   ├── 01_public_read_policies.sql
    │   ├── 02_user_ownership_policies.sql
    │   ├── 03_system_operation_policies.sql
    │   └── README.md
    ├── relationships/      # 🔗 Mapeamento de foreign keys
    │   ├── foreign_keys.sql
    │   └── README.md
    └── README.md           # 📚 Documentação da estrutura SQL
```

### 🗄️ **BANCO DE DADOS (14 TABELAS)**

```
📊 TABELAS PRINCIPAIS:
├── profiles              # Perfis dos usuários
├── posts                 # Posts do sistema  
├── comments              # Comentários nos posts
├── reactions             # Reações (likes, etc.)
├── feedbacks             # Sistema de feedbacks
├── follows               # Sistema de seguir usuários
├── user_points           # Pontuação dos usuários
├── user_badges           # Badges conquistados
├── user_streaks          # Streaks de engajamento
├── notifications         # Sistema de notificações
├── points_history        # Histórico de pontos
├── badges                # Definição dos badges
└── levels                # Níveis de gamificação
```

### 📱 **FRONTEND (Interface do Usuário)**

**Arquivo Principal:** `index.html` (raiz do projeto)

#### **Mapeamento de Funcionalidades no Frontend:**

```javascript
// AUTENTICAÇÃO (linhas ~850-950)
- login/logout
- verificação de sessão
- redirecionamentos

// POSTS/HOLOFOTES (linhas ~1000-1200)
- criação de posts
- renderização de posts
- modal de posts específicos ← IMPLEMENTADO RECENTEMENTE

// COMENTÁRIOS (linhas ~1200-1400)
- sistema de comentários
- modal de comentários
- processamento de @username ← IMPLEMENTADO RECENTEMENTE

// REAÇÕES (linhas ~1400-1500)
- curtidas/reações
- retry automático para erros de rede ← IMPLEMENTADO RECENTEMENTE
- sincronização offline

// GAMIFICAÇÃO (linhas ~1500-1700)
- pontos, badges, levels
- sistema de streaks
- notificações de level up

// NOTIFICAÇÕES (linhas ~1700-1900)
- sistema de notificações em tempo real
- "marcar todas como lidas" ← IMPLEMENTADO RECENTEMENTE
- modal de posts via notificação ← IMPLEMENTADO RECENTEMENTE

// PERFIL (linhas ~1900-2000+)
- dados do usuário
- modal de perfil via @username ← IMPLEMENTADO RECENTEMENTE
- estatísticas de engajamento
```

### 🗄️ **BACKEND (Banco de Dados)**

**Localização:** Pasta `sql/` (completamente organizada)

#### **Funções Críticas por Categoria:**

```sql
-- AUTENTICAÇÃO E SEGURANÇA
├── add_points_secure()           # Adicionar pontos com segurança
├── recalculate_user_points_secure() # Recalcular pontos
└── handle_*_secure()            # Funções com SECURITY DEFINER

-- SISTEMA DE STREAKS (CRÍTICO - RECÉM CORRIGIDO)
├── update_user_streak()         # ✅ SECURITY DEFINER adicionado
├── calculate_user_streak()      # ✅ SECURITY DEFINER adicionado
├── apply_streak_bonus_retroactive() # ✅ SECURITY DEFINER adicionado
└── update_user_streak_trigger() # ✅ Lógica condicional por tabela

-- NOTIFICAÇÕES (RECÉM IMPLEMENTADO)
├── mark_all_notifications_read() # ✅ Corrigido campo read_at
├── create_notification_no_duplicates() # Anti-spam
└── handle_*_notification_correto() # Funções de notificação

-- FEEDBACKS (RECÉM CORRIGIDO)
├── handle_feedback_notification_definitive() # ✅ NEW.author_id
├── handle_feedback_insert_secure() # Pontuação de feedbacks
└── notify_feedback_smart()      # ✅ NEW.author_id corrigido
```

## 🔧 **CASOS DE USO REAIS RESOLVIDOS**

### **📋 Caso 1: Erro "record 'new' has no field 'user_id'"**

**Problema:** Função tentava acessar campo inexistente
**Investigação:** `grep -n "NEW\.user_id" ALL_FUNCTIONS.sql`
**Causa Raiz:** Múltiplas funções usavam NEW.user_id em tabela feedbacks
**Solução:** Lógica condicional por tabela + correção sistemática

```sql
-- ANTES (problemático):
PERFORM update_user_streak(NEW.user_id);

-- DEPOIS (corrigido):
IF TG_TABLE_NAME = 'feedbacks' THEN
    PERFORM update_user_streak(NEW.author_id);
ELSE
    PERFORM update_user_streak(NEW.user_id);
END IF;
```

### **📋 Caso 2: Erro "new row violates row-level security policy"**

**Problema:** Função sem privilégios adequados
**Investigação:** Verificar políticas RLS + SECURITY DEFINER
**Causa Raiz:** Funções executavam com privilégios de usuário
**Solução:** SECURITY DEFINER + SET search_path

```sql
-- ANTES (problemático):
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql

-- DEPOIS (corrigido):
CREATE OR REPLACE FUNCTION update_user_streak(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
```

### **📋 Caso 3: Notificações Duplicadas**

**Problema:** Múltiplos triggers para mesma ação
**Investigação:** `grep -n "trigger.*comment" ALL_TRIGGERS.sql`
**Causa Raiz:** Dois triggers ativos para comentários
**Solução:** Remover trigger duplicado + documentar

```sql
-- PROBLEMA: Dois triggers ativos
CREATE TRIGGER comment_notification_correto_trigger ...
CREATE TRIGGER comment_notify_only_trigger ...

-- SOLUÇÃO: Apenas um trigger
CREATE TRIGGER comment_notification_correto_trigger ...
-- CREATE TRIGGER comment_notify_only_trigger ... (REMOVIDO)
```

## 🚀 **FUNCIONALIDADES IMPLEMENTADAS RECENTEMENTE**

### **✅ Modal de Post via Notificação**
- **Localização:** `index.html` linhas ~6000+
- **Funcionalidade:** Clicar em notificação abre modal do post
- **Implementação:** `showPostFromNotification()` + `renderSinglePost()`

### **✅ @username Clicável com Modal de Perfil**
- **Localização:** `index.html` linhas ~6100+
- **Funcionalidade:** @username vira link que abre perfil
- **Implementação:** `processUsernameLinks()` + `showUserProfileModal()`

### **✅ Retry Automático para Erros de Rede**
- **Localização:** `index.html` linhas ~5200+
- **Funcionalidade:** Retry com backoff exponencial
- **Implementação:** `retryWithBackoff()` + sincronização offline

### **✅ "Marcar Todas Como Lidas"**
- **Localização:** SQL functions + frontend
- **Funcionalidade:** Marcar todas notificações como lidas
- **Implementação:** `mark_all_notifications_read()` corrigida

## 🔍 **SCRIPTS DE DIAGNÓSTICO ESSENCIAIS**

### **🔧 Verificação Geral do Sistema**
```sql
-- Estado geral do banco
SELECT 'FUNÇÕES' as tipo, COUNT(*) as total 
FROM pg_proc WHERE pronamespace = 'public'::regnamespace
UNION ALL
SELECT 'TRIGGERS', COUNT(*) 
FROM pg_trigger WHERE tgrelid IN (
    SELECT oid FROM pg_class WHERE relnamespace = 'public'::regnamespace
)
UNION ALL
SELECT 'TABELAS', COUNT(*) 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### **🔧 Debug de Problemas Específicos**
```sql
-- Verificar função específica
SELECT proname, prosrc FROM pg_proc 
WHERE proname = 'nome_da_funcao';

-- Verificar triggers de uma tabela
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE table_name = 'nome_da_tabela';

-- Verificar estrutura de tabela
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'nome_da_tabela' 
ORDER BY ordinal_position;

-- Verificar políticas RLS
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'nome_da_tabela';
```

### **🔧 Verificação de Integridade**
```sql
-- Verificar se todas as funções críticas existem
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_user_streak') 
        THEN '✅ update_user_streak EXISTS'
        ELSE '❌ update_user_streak MISSING'
    END as status
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'mark_all_notifications_read') 
        THEN '✅ mark_all_notifications_read EXISTS'
        ELSE '❌ mark_all_notifications_read MISSING'
    END;
```

## 🎯 **REGRAS DE OURO PARA SUCESSO**

### **🔥 SEMPRE FAÇA:**
1. ✅ **Investigue antes de agir** - Use scripts de diagnóstico
2. ✅ **Corrija sistematicamente** - Todas as ocorrências, não apenas uma
3. ✅ **Teste com dados reais** - Não apenas teoria
4. ✅ **Documente mudanças** - Para futuras referências
5. ✅ **Commit com mensagens descritivas** - Explique problema + solução
6. ✅ **Adicione logs de debug** - Para facilitar troubleshooting futuro

### **🚫 NUNCA FAÇA:**
1. ❌ **Assumir que algo existe** sem verificar
2. ❌ **Corrigir apenas sintomas** sem encontrar causa raiz
3. ❌ **Executar SQL sem commitar** no GitHub primeiro
4. ❌ **Ignorar erros de RLS** - Sempre verificar SECURITY DEFINER
5. ❌ **Criar código duplicado** - Reutilizar funções existentes
6. ❌ **Commitar sem testar** - Sempre validar antes

## 📚 **RECURSOS ADICIONAIS**

### **🔗 Links Úteis**
- **Supabase Docs:** https://supabase.com/docs
- **PostgreSQL Functions:** https://www.postgresql.org/docs/current/sql-createfunction.html
- **RLS Policies:** https://www.postgresql.org/docs/current/ddl-rowsecurity.html

### **📞 Suporte**
- **Issues:** Use GitHub Issues para reportar problemas
- **Documentação:** Sempre atualizar README após mudanças significativas
- **Backup:** Sempre fazer backup antes de mudanças críticas

---

**🎉 Esta metodologia foi comprovada na prática e resultou em 100% de sucesso na resolução de problemas complexos. Siga exatamente estes passos para garantir o mesmo nível de qualidade e eficiência.**
