# 🌟 HoloSpot

Sistema de rede social com gamificação e notificações inteligentes.

## 🤖 **GUIA PARA NOVA IA - LEIA PRIMEIRO!**

Se você é uma nova IA assumindo este projeto, **este guia é essencial** para você se situar rapidamente e saber exatamente onde fazer alterações.

### 📊 **Status Atual do Projeto**
**Versão:** v6.0-complete  
**Status:** ✅ 100% Documentado e Organizado  
**Última atualização:** 2025-09-17

**IMPORTANTE:** Este projeto está **100% funcional** e **completamente documentado**. Não refaça nada do zero - tudo está organizado e pronto para uso.

## 🚨 **REGRAS FUNDAMENTAIS - NUNCA IGNORE!**

### **1. 🔍 NUNCA ASSUMIR - SEMPRE VERIFICAR**
- ❌ **NUNCA** assuma que funções/triggers existem
- ❌ **NUNCA** confie apenas na documentação
- ✅ **SEMPRE** extraia estado atual do banco antes de alterações
- ✅ **SEMPRE** verifique arquivos no GitHub

### **2. 📁 PROCESSO OBRIGATÓRIO DE COMMITS**
```bash
# ORDEM OBRIGATÓRIA:
1. Fazer alterações nos arquivos
2. git add .
3. git commit -m "mensagem descritiva"
4. git push
5. SÓ ENTÃO fornecer scripts SQL para execução
```

### **3. 🗄️ TRABALHO COM SUPABASE**
- ✅ **USUÁRIO executa** todas as queries no Supabase
- ✅ **IA fornece** scripts prontos para execução
- ❌ **NUNCA** executar queries sem commitar no GitHub primeiro
- ❌ **NUNCA** assumir que algo foi executado sem confirmação

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

#### **Estrutura do Frontend:**
```html
index.html
├── HTML Structure (linhas 1-200)
├── CSS Styles (linhas 201-800) 
├── JavaScript Logic (linhas 801-2000+)
└── Supabase Integration (distribuído no JS)
```

#### **Principais Seções do Código:**
- **Autenticação:** Linhas ~850-950 (login/logout)
- **Posts/Holofotes:** Linhas ~1000-1200 (criação e exibição)
- **Comentários:** Linhas ~1200-1400 (sistema de comentários)
- **Reações:** Linhas ~1400-1500 (curtidas/reações)
- **Gamificação:** Linhas ~1500-1700 (pontos, badges, levels)
- **Notificações:** Linhas ~1700-1900 (sistema de notificações)
- **Perfil:** Linhas ~1900-2000+ (dados do usuário)

### 🗄️ **BACKEND (Banco de Dados)**
**Localização:** Pasta `sql/` (completamente organizada)

#### **Estrutura do Backend:**
```
sql/
├── schema/        # 📋 Estruturas das tabelas (14 arquivos)
├── functions/     # 🔧 Lógica de negócio (6 arquivos)
├── triggers/      # ⚡ Automação (6 arquivos)
├── policies/      # 🔒 Segurança (4 arquivos)
└── data/          # 🎮 Dados iniciais (3 arquivos)
```

## 🛠️ **WORKFLOW OBRIGATÓRIO PARA ALTERAÇÕES**

### **📋 CHECKLIST ANTES DE QUALQUER ALTERAÇÃO**
1. ✅ **Ler este README** completamente
2. ✅ **Verificar estrutura** atual no GitHub  
3. ✅ **Extrair estado** do banco se necessário
4. ✅ **Planejar** mudanças sem assumir nada

### **🔄 PROCESSO PARA ALTERAÇÕES SQL (CRÍTICO)**
```bash
# ORDEM OBRIGATÓRIA - NUNCA INVERTER:

1. 📝 Modificar arquivo SQL em sql/
2. 💾 git add .
3. 💾 git commit -m "descrição clara"
4. 💾 git push
5. 📤 Fornecer script para usuário executar no Supabase
6. ✅ Aguardar confirmação de execução
7. 📋 Atualizar documentação se necessário
```

### **🔄 PROCESSO PARA ALTERAÇÕES FRONTEND**
```bash
# ORDEM RECOMENDADA:

1. 📝 Modificar index.html
2. 🧪 Testar no browser (se possível)
3. 💾 git add .
4. 💾 git commit -m "descrição clara"
5. 💾 git push
6. 📋 Documentar mudança se necessário
```

### **🚨 ERROS FATAIS A EVITAR**
- ❌ **Executar SQL** sem commitar no GitHub primeiro
- ❌ **Assumir** que funções/triggers existem
- ❌ **Criar duplicações** de código
- ❌ **Ignorar** a estrutura organizada
- ❌ **Commitar** sem testar
- ❌ **Criar placeholders** em vez de conteúdo real

### **✅ BOAS PRÁTICAS OBRIGATÓRIAS**
- ✅ **Verificar estado atual** antes de alterar
- ✅ **Manter organização** do GitHub
- ✅ **Fornecer scripts completos** para execução
- ✅ **Documentar mudanças** importantes
- ✅ **Seguir padrões** estabelecidos
- ✅ **Testar em ambiente real**

## 🔍 **COMO EXTRAIR ESTADO ATUAL DO BANCO**

### **📊 Script de Verificação Geral**
```sql
-- Execute no Supabase para verificar estado atual:
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

### **🔧 Scripts de Debug Específicos**
```sql
-- Verificar função específica:
SELECT proname, prosrc FROM pg_proc 
WHERE proname = 'nome_da_funcao';

-- Verificar triggers de uma tabela:
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE table_name = 'nome_da_tabela';

-- Verificar estrutura de tabela:
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'nome_da_tabela' 
ORDER BY ordinal_position;
```

## 🔧 **COMO FAZER ALTERAÇÕES ESPECÍFICAS**

### 📱 **ALTERAÇÕES NO FRONTEND**

#### **Para Modificar a Interface:**
1. **Abra:** `index.html`
2. **CSS:** Linhas 201-800 (estilos visuais)
3. **HTML:** Linhas 1-200 (estrutura da página)

#### **Para Modificar Funcionalidades:**
1. **Abra:** `index.html`
2. **JavaScript:** Linhas 801-2000+
3. **Localize a função específica** (veja mapeamento abaixo)

#### **Principais Seções do Código:**
- **Autenticação:** Linhas ~850-950 (login/logout)
- **Posts/Holofotes:** Linhas ~1000-1200 (criação e exibição)
- **Comentários:** Linhas ~1200-1400 (sistema de comentários)
- **Reações:** Linhas ~1400-1500 (curtidas/reações)
- **Gamificação:** Linhas ~1500-1700 (pontos, badges, levels)
- **Notificações:** Linhas ~1700-1900 (sistema de notificações)
- **Perfil:** Linhas ~1900-2000+ (dados do usuário)

### 🗄️ **ALTERAÇÕES NO BACKEND**

#### **Para Modificar Estrutura de Tabelas:**
1. **Consulte:** `sql/schema/` 
2. **Encontre a tabela:** `01_badges.sql`, `02_comments.sql`, etc.
3. **Modifique:** Estrutura, campos, constraints

#### **Para Modificar Lógica de Negócio:**
1. **Consulte:** `sql/functions/ALL_FUNCTIONS.sql`
2. **Localize** a função específica (116 funções organizadas)
3. **Modifique** conforme necessário

#### **Para Modificar Automação:**
1. **Consulte:** `sql/triggers/ALL_TRIGGERS.sql`
2. **Localize** o trigger específico (29 triggers organizados)
3. **Modifique** conforme necessário

#### **Para Modificar Segurança:**
1. **Consulte:** `sql/policies/`
2. **Tipos disponíveis:**
   - `01_public_read_policies.sql` - Dados públicos
   - `02_user_ownership_policies.sql` - Dados privados
   - `03_system_operation_policies.sql` - Operações do sistema

## 🚨 **TROUBLESHOOTING E DEBUGGING**

### **🔍 Problemas de Notificações**
```sql
-- Verificar se triggers estão ativos:
SELECT schemaname, tablename, trigger_name, event_manipulation 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
ORDER BY table_name;

-- Verificar notificações recentes:
SELECT * FROM notifications 
WHERE created_at > NOW() - INTERVAL '1 hour' 
ORDER BY created_at DESC;
```

### **🔍 Problemas de Pontuação**
```sql
-- Verificar histórico de pontos:
SELECT user_id, action_type, points_earned, created_at 
FROM points_history 
WHERE created_at > NOW() - INTERVAL '1 day' 
ORDER BY created_at DESC;

-- Verificar função update_user_total_points:
SELECT proname, prosrc FROM pg_proc 
WHERE proname = 'update_user_total_points';
```

### **🔍 Problemas de Streaks**
```sql
-- Verificar streaks atuais:
SELECT user_id, current_streak, last_activity_date 
FROM user_streaks 
ORDER BY current_streak DESC;

-- Verificar função de cálculo de streak:
SELECT proname, prosrc FROM pg_proc 
WHERE proname LIKE '%streak%';
```

### **📊 Monitoramento do Sistema**
```sql
-- Estatísticas gerais:
SELECT 
    'profiles' as tabela, COUNT(*) as registros FROM profiles
UNION ALL
SELECT 'posts', COUNT(*) FROM posts
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL
SELECT 'points_history', COUNT(*) FROM points_history;

-- Verificar usuários ativos:
SELECT COUNT(DISTINCT user_id) as usuarios_ativos 
FROM points_history 
WHERE created_at > NOW() - INTERVAL '7 days';
```

## 🔄 **PROCESSO DE MANUTENÇÃO**

### **📅 Rotina Recomendada**
1. **Verificar logs** de erro no Supabase
2. **Monitorar performance** das queries
3. **Revisar notificações** não entregues
4. **Atualizar documentação** se necessário

### **🔧 Fluxo de Correção de Bugs**
1. **Problema identificado** → Extrair estado atual
2. **Análise** → Verificar logs e dados
3. **Solução** → Criar migration/correção
4. **Commit** → GitHub primeiro, sempre
5. **Deploy** → Fornecer script para Supabase
6. **Teste** → Validar em ambiente real
7. **Documentar** → Atualizar se necessário

## 📋 **TABELAS PRINCIPAIS E SUAS FUNÇÕES**

### **Core System (Interação Social):**
- **`profiles`** - Usuários da plataforma
- **`posts`** - Holofotes e reconhecimentos
- **`comments`** - Comentários em posts
- **`reactions`** - Curtidas e reações
- **`follows`** - Relacionamentos sociais

### **Gamification (Sistema de Pontos):**
- **`badges`** - 23 conquistas disponíveis
- **`levels`** - 10 níveis de progressão
- **`user_points`** - Pontuação de cada usuário
- **`user_badges`** - Badges conquistados
- **`user_streaks`** - Sequências de atividade

### **Notifications & History:**
- **`notifications`** - Sistema de notificações
- **`points_history`** - Histórico de pontuação
- **`feedbacks`** - Sistema de feedback

## 🎮 **SISTEMAS IMPLEMENTADOS**

### **🏆 Sistema de Gamificação**
- **Pontos:** Sistema completo de pontuação por ações
- **Níveis:** Progressão automática baseada em pontos
- **Badges:** Conquistas por critérios específicos
- **Streaks:** Dias consecutivos de engajamento
- **Notificações:** Alertas em tempo real para level-ups e milestones

### **⚡ Funcionalidades Técnicas**
- **Triggers automáticos** para atualização de pontos e níveis
- **Notificações em tempo real** via Supabase
- **Sistema de segurança** com políticas RLS
- **Cálculo automático** de streaks e bônus
- **Interface responsiva** para desktop e mobile

### **Sistema de Pontuação:**
- **Posts:** 10 pontos base
- **Comments:** 5 pontos base
- **Reactions:** 2 pontos base
- **Feedbacks:** 15 pontos base
- **Bônus por raridade de badge:** common(+5), rare(+10), epic(+25), legendary(+50)

### **Badges e Levels:**
- **23 badges** organizados por categoria (milestone, engagement, social, special)
- **10 levels** de Novato (0-99 pontos) a Hall da Fama (32.000+ pontos)
- **Verificação automática** via triggers

## 📚 **DOCUMENTAÇÃO COMPLETA**

### **Leitura Obrigatória:**
1. **`sql/README.md`** - Guia principal do SQL
2. **`sql/functions/README.md`** - Guia de funções
3. **`sql/triggers/README.md`** - Guia de triggers
4. **`sql/schema/README.md`** - Guia de deployment
5. **`sql/policies/README.md`** - Guia de segurança
6. **`sql/data/README.md`** - Guia de dados iniciais

### **🔗 Links Importantes**
- **GitHub Repository:** https://github.com/holospotadm/holospot
- **Supabase Dashboard:** [Configurado pelo usuário]
- **Frontend URL:** [Configurado pelo usuário]

### **🔧 Ferramentas Utilizadas**
- **Backend:** Supabase (PostgreSQL)
- **Frontend:** HTML5 + CSS3 + JavaScript (Vanilla)
- **Autenticação:** Supabase Auth
- **Real-time:** Supabase Realtime
- **Versionamento:** Git + GitHub

## 🎯 **OBJETIVOS ALCANÇADOS**

Este projeto está **100% funcional** e **completamente documentado**:
- ✅ **14 tabelas** documentadas
- ✅ **29 triggers** organizados
- ✅ **116 funções** mapeadas
- ✅ **Políticas RLS** configuradas
- ✅ **23 badges + 10 levels** funcionais
- ✅ **Sistema de streaks** automático
- ✅ **Notificações em tempo real**

## 📞 **SUPORTE E CONTATO**

### **🆘 Em Caso de Problemas**
1. **Verificar logs** do Supabase
2. **Consultar documentação** deste README
3. **Extrair estado atual** do banco
4. **Seguir processo** de troubleshooting

### **📝 Reportar Bugs**
1. **Descrever problema** detalhadamente
2. **Incluir logs** relevantes
3. **Especificar ambiente** (produção/desenvolvimento)
4. **Seguir template** de issue no GitHub

---

**🤖 Lembre-se: Este projeto está completo e funcional. Sua missão é evoluir, não reconstruir!**

**🌟 HoloSpot - Conectando pessoas através de gamificação inteligente**

---

*Última atualização: 2025-09-17*  
*Versão: v6.0-complete*  
*Estrutura SQL: Completa e organizada*

