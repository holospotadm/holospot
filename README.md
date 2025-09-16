# 🌟 HoloSpot

Sistema de rede social com gamificação e notificações inteligentes.

## 🤖 **GUIA PARA NOVA IA - LEIA PRIMEIRO!**

Se você é uma nova IA assumindo este projeto, **este guia é essencial** para você se situar rapidamente e saber exatamente onde fazer alterações.

### 📊 **Status Atual do Projeto**
**Versão:** v5.0-complete  
**Status:** ✅ 100% Documentado e Organizado  
**Última atualização:** 2025-09-16

**IMPORTANTE:** Este projeto está **100% funcional** e **completamente documentado**. Não refaça nada do zero - tudo está organizado e pronto para uso.

## 🎯 **ONDE ENCONTRAR CADA COISA**

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

## 🔧 **COMO FAZER ALTERAÇÕES**

### 📱 **ALTERAÇÕES NO FRONTEND**

#### **Para Modificar a Interface:**
1. **Abra:** `index.html`
2. **CSS:** Linhas 201-800 (estilos visuais)
3. **HTML:** Linhas 1-200 (estrutura da página)

#### **Para Modificar Funcionalidades:**
1. **Abra:** `index.html`
2. **JavaScript:** Linhas 801-2000+
3. **Localize a função específica** (veja mapeamento acima)

#### **Exemplos Práticos:**
```javascript
// Adicionar nova funcionalidade de post
// Localização: ~linha 1000-1200
async function createPost() { ... }

// Modificar sistema de pontos
// Localização: ~linha 1500-1700
function updateUserPoints() { ... }

// Alterar notificações
// Localização: ~linha 1700-1900
function handleNotifications() { ... }
```

### 🗄️ **ALTERAÇÕES NO BACKEND**

#### **Para Modificar Estrutura de Tabelas:**
1. **Consulte:** `sql/schema/` 
2. **Encontre a tabela:** `01_badges.sql`, `02_comments.sql`, etc.
3. **Modifique:** Estrutura, campos, constraints

#### **Para Modificar Lógica de Negócio:**
1. **Consulte:** `sql/functions/`
2. **Categorias disponíveis:**
   - `01_audit_functions.sql` - Auditoria
   - `02_gamification_functions.sql` - Gamificação
   - `03_notification_functions.sql` - Notificações
   - `04_security_functions.sql` - Segurança
   - `05_utility_functions.sql` - Utilitários

#### **Para Modificar Automação:**
1. **Consulte:** `sql/triggers/`
2. **Categorias disponíveis:**
   - `01_audit_triggers.sql` - Campos updated_at
   - `02_gamification_triggers.sql` - Badges automáticos
   - `03_notification_triggers.sql` - Notificações automáticas
   - `04_security_triggers.sql` - Validações
   - `05_utility_triggers.sql` - Utilitários

#### **Para Modificar Segurança:**
1. **Consulte:** `sql/policies/`
2. **Tipos disponíveis:**
   - `01_public_read_policies.sql` - Dados públicos
   - `02_user_ownership_policies.sql` - Dados privados
   - `03_system_operation_policies.sql` - Operações do sistema

## 📋 **TABELAS PRINCIPAIS E SUAS FUNÇÕES**

### **Core System (Interação Social):**
- **`profiles`** - Usuários da plataforma
- **`posts`** - Holofotes e reconhecimentos
- **`comments`** - Comentários em posts
- **`reactions`** - Curtidas e reações
- **`follows`** - Relacionamentos sociais

### **Gamification (Sistema de Pontos):**
- **`badges`** - 20 conquistas disponíveis
- **`levels`** - 10 níveis de progressão
- **`user_points`** - Pontuação de cada usuário
- **`user_badges`** - Badges conquistados
- **`user_streaks`** - Sequências de atividade

### **Notifications & History:**
- **`notifications`** - Sistema de notificações
- **`points_history`** - Histórico de pontuação
- **`feedbacks`** - Sistema de feedback

## 🚨 **REGRAS IMPORTANTES - NUNCA IGNORE!**

### **Estrutura das Tabelas (CRÍTICO):**
- **`feedbacks.author_id`** = autor do POST (não quem deu feedback)
- **`feedbacks.mentioned_user_id`** = quem deu o feedback
- **`posts.mentioned_user_id`** = quem foi mencionado (holofote)
- **`follows.follower_id`** = quem segue
- **`follows.following_id`** = quem é seguido

### **Sistema de Pontuação:**
- **Posts:** 10 pontos base
- **Comments:** 5 pontos base
- **Reactions:** 2 pontos base
- **Feedbacks:** 15 pontos base
- **Bônus por raridade de badge:** common(0), uncommon(+5), rare(+10), epic(+25), legendary(+50)

### **Badges e Levels:**
- **20 badges** organizados por categoria (milestone, engagement, social, special)
- **10 levels** de Novato (0-99 pontos) a Imortal (10.000+ pontos)
- **Verificação automática** via triggers

## 🔍 **COMO DIAGNOSTICAR PROBLEMAS**

### **Frontend (Interface):**
1. **Abra o Console do Browser** (F12)
2. **Verifique erros JavaScript**
3. **Teste conexão com Supabase**

### **Backend (Banco):**
1. **Acesse Supabase Dashboard**
2. **Verifique logs de erro**
3. **Execute:** Scripts de verificação em `sql/`

## 📚 **DOCUMENTAÇÃO COMPLETA**

### **Leitura Obrigatória:**
1. **`docs/DATABASE_COMPLETE.md`** - Documentação final 100%
2. **`docs/DATABASE_SCHEMA_REAL.md`** - Schema baseado na extração real
3. **`docs/ESTADO_ATUAL.md`** - Status atual do sistema

### **Guias Específicos:**
- **`sql/README.md`** - Guia principal do SQL
- **`sql/schema/README.md`** - Guia de deployment
- **`sql/functions/README.md`** - Guia de funções
- **`sql/triggers/README.md`** - Guia de triggers
- **`sql/policies/README.md`** - Guia de segurança
- **`sql/data/README.md`** - Guia de dados iniciais

## 🛠️ **WORKFLOW RECOMENDADO**

### **Para Qualquer Alteração:**
1. **📖 Leia a documentação** relevante primeiro
2. **🔍 Localize** o arquivo correto (frontend ou backend)
3. **✏️ Faça a alteração** específica
4. **🧪 Teste** a funcionalidade
5. **📝 Documente** a mudança
6. **💾 Commit** com mensagem descritiva

### **Exemplo de Fluxo:**
```bash
# 1. Entender o que precisa ser alterado
# 2. Localizar arquivo correto
# 3. Fazer alteração
# 4. Testar
git add .
git commit -m "feat: add new badge for streak milestone"
git push origin main
```

## 🎮 **FUNCIONALIDADES PRINCIPAIS**

### **Sistema de Holofotes:**
- Usuários podem destacar outros usuários em posts
- Menções com @ geram notificações
- Sistema de pontuação automático

### **Gamificação Completa:**
- **20 badges** automáticos por conquistas
- **10 levels** de progressão
- **Sistema de streaks** com multiplicadores
- **Pontuação** por todas as ações

### **Notificações Inteligentes:**
- **Anti-spam** com agrupamento
- **Tempo real** via Supabase
- **Mensagens padronizadas**

## 🔗 **CONEXÕES IMPORTANTES**

### **Supabase (Backend):**
- **URL:** Configurado no frontend
- **Autenticação:** Row Level Security (RLS)
- **Real-time:** Subscriptions ativas

### **Frontend ↔ Backend:**
- **Autenticação:** `auth.users` ↔ `profiles`
- **Posts:** JavaScript ↔ `posts` table
- **Pontuação:** Automática via triggers
- **Notificações:** Real-time subscriptions

## ⚠️ **AVISOS CRÍTICOS**

### **NÃO FAÇA:**
- ❌ **Não refaça** estruturas existentes
- ❌ **Não ignore** a documentação
- ❌ **Não altere** estruturas de tabelas sem consultar `sql/schema/`
- ❌ **Não modifique** triggers sem entender dependências

### **SEMPRE FAÇA:**
- ✅ **Consulte** documentação primeiro
- ✅ **Teste** em ambiente de desenvolvimento
- ✅ **Mantenha** consistência com padrões existentes
- ✅ **Documente** suas alterações

## 🎯 **OBJETIVOS ALCANÇADOS**

Este projeto está **100% funcional** e **completamente documentado**:
- ✅ **14 tabelas** documentadas
- ✅ **23 triggers** organizados
- ✅ **18 funções** mapeadas
- ✅ **60 policies RLS** configuradas
- ✅ **20 badges + 10 levels** funcionais

## 📞 **Suporte e Recursos**

### **Em Caso de Dúvidas:**
1. **Consulte** a documentação em `docs/`
2. **Verifique** os READMEs específicos em cada pasta
3. **Execute** scripts de verificação
4. **Analise** o código existente como referência

### **Recursos Úteis:**
- **Supabase Dashboard** - Logs e métricas
- **Browser Console** - Debug do frontend
- **Git History** - Histórico de mudanças

---

**🤖 Lembre-se: Este projeto está completo e funcional. Sua missão é evoluir, não reconstruir!**

**🌟 HoloSpot - Conectando pessoas através de gamificação inteligente**

