# 🌟 HoloSpot

Sistema de rede social com gamificação e notificações inteligentes.

## 🤖 **GUIA PARA NOVA IA - METODOLOGIA COMPROVADA**

Se você é uma nova IA assumindo este projeto, **este guia contém a metodologia exata** que foi usada com sucesso para resolver problemas complexos e implementar funcionalidades avançadas.

### 📊 **Status Atual do Projeto**

**Versão:** v7.0-autonomous  
**Status:** ✅ 100% Documentado e Organizado  
**Última atualização:** 2026-04-06  
**Metodologia:** ✅ Comprovada e Testada

**IMPORTANTE:** Este projeto está **100% funcional** e **completamente documentado**. Não refaça nada do zero - tudo está organizado e pronto para uso.

## 🚨 **METODOLOGIA COMPROVADA - SIGA EXATAMENTE!**

### **🔍 1. PRINCÍPIO FUNDAMENTAL: INVESTIGAÇÃO ANTES DE AÇÃO**

**NUNCA assuma nada. SEMPRE investigue primeiro.**

#### **Processo de Investigação Comprovado:**
```shell
# METODOLOGIA REAL QUE FUNCIONOU 100%:
1. 🔍 Reproduzir o erro exato (copiar mensagem completa)
2. 🔍 Buscar no GitHub com grep nos arquivos SQL/HTML
3. 🔍 Identificar causa raiz através do código no GitHub
4. 🔍 Analisar TODAS as ocorrências do problema
5. 🔍 Corrigir sistematicamente (não apenas uma ocorrência)
6. ✅ Executar SQL no banco via exec_sql e validar
7. ✅ Commitar correção no GitHub
```

#### **🎯 PREMISSA FUNDAMENTAL:**
**GitHub = Estado atual do banco** (fonte da verdade)
- ✅ Trabalhar com base nos arquivos commitados
- ✅ Confiar no código do GitHub como verdade
- ✅ O agente pode (e deve) extrair o estado do banco via API para validar sincronia
- ✅ Testar lógica com dados reais do banco antes de commitar

#### **🔧 Scripts de Verificação (Último Recurso):**
**Use APENAS se houver suspeita de dessincronia GitHub ↔ Banco**

```sql
-- SÓ usar SE houver dúvida sobre sincronia:
-- 1. VERIFICAR SE FUNÇÃO EXISTE NO BANCO
SELECT proname FROM pg_proc WHERE proname = 'funcao_suspeita';

-- 2. VERIFICAR TRIGGERS ATIVOS
SELECT trigger_name FROM information_schema.triggers 
WHERE table_name = 'tabela_suspeita';

-- 3. VERIFICAR ESTRUTURA DE TABELA (se erro de campo)
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'tabela_suspeita';
```

#### **📋 Quando Extrair do Banco:**
- 🤔 Erro não faz sentido com código do GitHub?
- 🤔 Suspeita de função/trigger não commitado?
- 🤔 Comportamento inconsistente reportado?

**SE NÃO → Trabalhar apenas com GitHub (metodologia comprovada)**

### **🔧 2. METODOLOGIA DE RESOLUÇÃO DE PROBLEMAS**

#### **Processo Comprovado para Erros SQL:**

**EXEMPLO REAL:** Erro `record "new" has no field "user_id"`

```shell
# PROCESSO REAL QUE FUNCIONOU:
1. 🔍 Buscar TODAS as ocorrências no GitHub
   grep -n "NEW\.user_id" sql/functions/*.sql

2. 🔍 Analisar código e identificar campo correto
   # Verificar schema no GitHub: sql/schema/08_feedbacks.sql
   # Campo correto: NEW.author_id (não NEW.user_id)

3. 🔍 Mapear fluxo de execução através do código
   # INSERT feedbacks → trigger update_streak_after_feedback 
   # → função update_user_streak_trigger() → erro NEW.user_id

4. 🔍 Identificar TODAS as funções afetadas
   # update_user_streak_trigger, notify_feedback_smart, etc.

5. ✅ Corrigir TODAS as ocorrências sistematicamente
6. ✅ Adicionar lógica condicional por tabela se necessário
7. ✅ Commitar no GitHub PRIMEIRO
8. ✅ Fornecer script SQL para execução pelo usuário
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
1. 📝 Investigar problema (consultando código ou banco via API)
2. 📝 Modificar arquivos SQL/HTML localmente
3. ⚡ Executar SQL diretamente no Supabase via exec_sql e validar
4. 💾 git add .
5. 💾 git commit -m "fix: Descrição específica do problema resolvido"
6. 💾 git push origin main (dispara deploy Vercel)
7. ✅ Informar usuário que a alteração está no ar
8. 📋 Documentar se necessário
```

#### **⚠️ IMPORTANTE: Fluxo de Execução SQL**

```
┌─────────┐     SQL via API REST   ┌─────────┐
│  Manus  │ ────────────────────▶  │Supabase │
│         │                        │         │
│ (edita  │                        │(executa │
│ GitHub) │                        │ banco)  │
└─────────┘                        └─────────┘
     │                                  ▲
     │         monitora deploy          │
     └──────────────────────────────────┘
```

**A IA executa o SQL diretamente no Supabase via API REST (exec_sql) e edita o GitHub. O usuário apenas toma decisões de produto.**

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
- [ ] ✅ Verifiquei o estado atual no GitHub?
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
- ❌ **Criar migrations sem atualizar arquivos principais** (functions, triggers, etc)

## 🎯 **ONDE ENCONTRAR CADA COISA**

### 🏗️ **ESTRUTURA COMPLETA DO PROJETO**

```
holospot/
├── index.html              # 📱 Frontend principal (HTML + CSS + JavaScript)
├── README.md               # 📖 Este arquivo (instruções completas)
└── sql/                    # 🗄️ Estrutura completa do banco de dados
    ├── schema/             # 📋 Definições das tabelas (21 tabelas)
    │   └── NN_tabela.sql   # Formato: 01_badges.sql, 15_posts.sql, etc.
    ├── functions/          # 🔧 Funções PostgreSQL (166 funções)
    │   └── nome_funcao.sql # 1 arquivo por função
    ├── triggers/           # ⚡ Triggers PostgreSQL (35 triggers)
    │   └── tabela_triggers.sql # Agrupados por tabela
    ├── constraints/        # 🔗 Constraints (138 constraints)
    │   └── tabela_constraints.sql # Agrupados por tabela
    ├── policies/           # 🔒 Políticas RLS (85 policies)
    │   └── tabela_policies.sql # Agrupados por tabela
    ├── migrations/         # 📦 Migrações incrementais
    │   └── YYYYMMDD_descricao.sql
    └── README.md           # 📚 Documentação técnica da estrutura SQL
```

### 🗄️ **BANCO DE DADOS (21 TABELAS)**

```
📊 TABELAS PRINCIPAIS:
├── profiles              # Perfis dos usuários
├── posts                 # Posts/holofotes do sistema  
├── comments              # Comentários nos posts
├── reactions             # Reações (loved ❤️, claps 👏, hug 🫂)
├── feedbacks             # Sistema de feedbacks
├── follows               # Sistema de seguir usuários
├── notifications         # Sistema de notificações
│
📊 GAMIFICAÇÃO:
├── user_points           # Pontuação dos usuários
├── user_badges           # Badges conquistados
├── user_streaks          # Streaks de engajamento
├── points_history        # Histórico de pontos
├── badges                # Definição dos badges
├── levels                # Níveis de gamificação
│
📊 COMUNIDADES E CORRENTES:
├── communities           # Comunidades
├── community_members     # Membros das comunidades
├── chains                # Correntes de reconhecimento
├── chain_posts           # Posts das correntes
│
📊 COMUNICAÇÃO:
├── conversations         # Conversas privadas
├── messages              # Mensagens das conversas
│
📊 ACESSO:
├── invites               # Códigos de convite
└── waitlist              # Lista de espera
```

### 📱 **FRONTEND (Interface do Usuário)**

**Arquivo Principal:** `index.html` (raiz do projeto)

#### **Mapeamento de Funcionalidades no Frontend:**

```javascript
// AUTENTICAÇÃO
- login/logout
- verificação de sessão
- redirecionamentos

// POSTS/HOLOFOTES
- criação de posts
- renderização de posts
- modal de posts específicos

// REAÇÕES (ATUALIZADO 2026-01-28)
- tipos: loved (❤️), claps (👏), hug (🫂)
- toggleReaction() otimizada (1-2 requests por reação)
- atualização de UI em tempo real

// COMENTÁRIOS
- sistema de comentários
- modal de comentários
- processamento de @username

// GAMIFICAÇÃO
- pontos, badges, levels
- sistema de streaks
- notificações de level up

// NOTIFICAÇÕES
- sistema de notificações em tempo real
- "marcar todas como lidas"
- modal de posts via notificação

// PERFIL
- dados do usuário
- modal de perfil via @username
- estatísticas de engajamento
- índice holospot (bem-estar social)

// MEMÓRIAS VIVAS (60+)
- feed exclusivo
- 6 tipos de posts próprios
- correntes exclusivas

// ONBOARDING
- tour guiado com Shepherd.js
- tooltips interativos
```

### 🗄️ **BACKEND (Banco de Dados)**

**Localização:** Pasta `sql/` (completamente organizada)

**📚 Documentação completa:** Ver `sql/README.md`

#### **Funções Críticas por Categoria:**

```sql
-- AUTENTICAÇÃO E SEGURANÇA
├── add_points_secure()           # Adicionar pontos com segurança
├── recalculate_user_points_secure() # Recalcular pontos
└── handle_*_secure()            # Funções com SECURITY DEFINER

-- SISTEMA DE STREAKS
├── update_user_streak()         # ✅ SECURITY DEFINER
├── calculate_user_streak()      # ✅ SECURITY DEFINER
├── apply_streak_bonus_retroactive() # ✅ SECURITY DEFINER
└── update_user_streak_trigger() # ✅ Lógica condicional por tabela

-- NOTIFICAÇÕES
├── mark_all_notifications_read() # Marcar todas como lidas
├── create_notification_no_duplicates() # Anti-spam
└── handle_*_notification_*()    # Funções de notificação

-- REAÇÕES (ATUALIZADO 2025-12-29)
├── handle_reaction_simple()     # Notificação de reação
└── Tipos: loved, claps, hug     # Constraint reactions_type_check

-- GAMIFICAÇÃO
├── calculate_holospot_index()   # Índice de engajamento
├── check_and_award_badges()     # Verificar e conceder badges
└── add_points_to_user()         # Adicionar pontos
```

## 🔧 **CASOS DE USO REAIS RESOLVIDOS**

### **📋 Caso 1: Erro "record 'new' has no field 'user_id'"**

**Problema:** Função tentava acessar campo inexistente
**Investigação:** `grep -n "NEW\.user_id" sql/functions/*.sql`
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

### **📋 Caso 3: Reações não salvando (2025-12-29)**

**Problema:** Erro `violates check constraint "reactions_type_check"`
**Investigação:** Verificar constraint da tabela reactions
**Causa Raiz:** Constraint só aceitava tipos antigos (touched, grateful, inspired)
**Solução:** Atualizar constraint para novos tipos (loved, claps, hug)

```sql
-- CORREÇÃO:
ALTER TABLE public.reactions DROP CONSTRAINT IF EXISTS reactions_type_check;
ALTER TABLE public.reactions 
ADD CONSTRAINT reactions_type_check 
CHECK (type IN ('loved', 'claps', 'hug', 'touched', 'grateful', 'inspired'));
```

### **📋 Caso 4: 100+ requests por reação (2025-12-29)**

**Problema:** Função toggleReaction fazia muitas chamadas ao banco
**Investigação:** Análise do código frontend
**Causa Raiz:** Chamadas desnecessárias a updateMetricsRealTime, reRenderPostsRealTime, etc.
**Solução:** Otimizar para 1-2 requests + atualização local da UI

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

-- Verificar constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'nome_da_tabela';
```

## 🎯 **REGRAS DE OURO PARA SUCESSO**

### **🔥 SEMPRE FAÇA:**
1. ✅ **Investigue antes de agir** - Use scripts de diagnóstico
2. ✅ **Corrija sistematicamente** - Todas as ocorrências, não apenas uma
3. ✅ **Teste com dados reais** - Não apenas teoria
4. ✅ **Documente mudanças** - Para futuras referências
5. ✅ **Commit com mensagens descritivas** - Explique problema + solução
6. ✅ **Adicione logs de debug** - Para facilitar troubleshooting futuro
7. ✅ **Atualize arquivos principais após migrations** - Manter GitHub sincronizado
8. ✅ **Use o script de setup (HOLOSPOT_setup.sh)** - Para carregar credenciais no início de cada task

### **🚫 NUNCA FAÇA:**
1. ❌ **Assumir que algo existe** sem verificar
2. ❌ **Corrigir apenas sintomas** sem encontrar causa raiz
3. ❌ **Esquecer de commitar no GitHub** após executar SQL no banco
4. ❌ **Ignorar erros de RLS** - Sempre verificar SECURITY DEFINER
5. ❌ **Criar código duplicado** - Reutilizar funções existentes
6. ❌ **Commitar sem testar** - Sempre validar antes
7. ❌ **Criar migrations sem atualizar arquivos principais** - GitHub deve refletir o banco

## 🔑 **CREDENCIAIS DE ACESSO**

### **GitHub Repository Access**
- **Username:** `holospotadm`
- **Token:** `[FORNECIDO SEPARADAMENTE POR SEGURANÇA]`
- **Repository:** `https://github.com/holospotadm/holospot`

### **Como Usar as Credenciais:**
```bash
# Clonar repositório (substitua TOKEN pelo token fornecido)
git clone https://holospotadm:TOKEN@github.com/holospotadm/holospot.git

# Configurar remote para push (substitua TOKEN pelo token fornecido)
git remote set-url origin https://holospotadm:TOKEN@github.com/holospotadm/holospot.git

# Fazer push das alterações
git push origin main
```

**⚠️ IMPORTANTE:** Por segurança, o token não é armazenado diretamente no código. Solicite o token atual ao administrador do projeto ou consulte as variáveis de ambiente seguras.

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
