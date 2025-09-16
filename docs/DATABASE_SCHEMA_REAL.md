# 📊 ESQUEMA REAL DO BANCO DE DADOS - HoloSpot

**Baseado em extração real do banco em:** 2025-09-16 02:16:56  
**Total de tabelas:** 14  
**Schema:** public

---

## 📋 TABELAS EXISTENTES

### **Core Tables (9)**
- `badges` - Definição de badges/emblemas
- `comments` - Comentários em posts
- `feedbacks` - Sistema de feedbacks
- `follows` - Relacionamentos de seguir
- `notifications` - Sistema de notificações
- `points_history` - Histórico de pontuação
- `posts` - Posts principais
- `profiles` - Perfis de usuários
- `reactions` - Reações em posts

### **Gamification Tables (4)**
- `user_badges` - Badges conquistados por usuários
- `user_points` - Pontuação total dos usuários
- `user_streaks` - Sistema de streaks
- `levels` - Definição de níveis (descoberta!)

### **Debug Tables (1)**
- `debug_feedback_test` - Tabela de teste (temporária)

---

## 🔍 ESTRUTURA DETALHADA

### **🏆 badges**
```sql
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(10) NOT NULL,
    category VARCHAR(50) NOT NULL,
    points_required INTEGER DEFAULT 0,
    condition_type VARCHAR(50) NOT NULL,
    condition_value INTEGER NOT NULL,
    rarity VARCHAR(20) DEFAULT 'common',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

**Campos importantes:**
- `condition_type` + `condition_value` = Critério para conquistar
- `rarity` = common, rare, epic, legendary
- `points_required` = Pontos necessários (se aplicável)

### **💬 comments**
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id),
    user_id UUID REFERENCES profiles(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

**Relacionamentos:**
- `post_id` → `posts.id` (post comentado)
- `user_id` → `profiles.id` (quem comentou)

### **📝 feedbacks**
```sql
CREATE TABLE feedbacks (
    id BIGINT PRIMARY KEY,  -- ⚠️ BIGINT, não UUID!
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    post_id UUID DEFAULT gen_random_uuid(),
    author_id UUID DEFAULT gen_random_uuid(),  -- ⚠️ AUTOR DO POST
    feedback_text TEXT,
    mentioned_user_id UUID  -- ⚠️ QUEM DEU O FEEDBACK
);
```

**⚠️ ESTRUTURA CRÍTICA:**
- `author_id` = **AUTOR DO POST** (quem recebe notificação)
- `mentioned_user_id` = **QUEM DEU FEEDBACK** (remetente)
- `id` = **BIGINT** (não UUID como outras tabelas)

### **👥 follows**
```sql
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES profiles(id),
    following_id UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);
```

**Relacionamentos:**
- `follower_id` = quem está seguindo
- `following_id` = quem está sendo seguido

### **🔔 notifications**
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    from_user_id UUID REFERENCES profiles(id),
    type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    -- Campos adicionais da Fase 5:
    group_key VARCHAR(255),
    priority INTEGER DEFAULT 1,
    reference_id UUID,
    reference_type VARCHAR(50)
);
```

**Tipos de notificação:**
- `reaction`, `comment`, `feedback`, `follow`, `badge_earned`, `level_up`

---

## 🔗 RELACIONAMENTOS PRINCIPAIS

### **Posts → Interações**
```
posts (id) ←── comments (post_id)
posts (id) ←── reactions (post_id)  
posts (id) ←── feedbacks (post_id)
```

### **Usuários → Ações**
```
profiles (id) ←── comments (user_id)
profiles (id) ←── reactions (user_id)
profiles (id) ←── follows (follower_id, following_id)
profiles (id) ←── notifications (user_id, from_user_id)
```

### **Gamificação**
```
profiles (id) ←── user_points (user_id)
profiles (id) ←── user_badges (user_id)
profiles (id) ←── user_streaks (user_id)
profiles (id) ←── points_history (user_id)
```

---

## ⚠️ DESCOBERTAS IMPORTANTES

### **1. Tabela `levels` Existe!**
- Não estava documentada anteriormente
- Precisa investigar estrutura completa

### **2. Estrutura `feedbacks` Diferente**
- `id` é BIGINT (não UUID)
- `author_id` = autor do POST (não do feedback)
- `mentioned_user_id` = quem deu feedback

### **3. Campos Adicionais em `notifications`**
- `group_key`, `priority`, `reference_id`, `reference_type`
- Implementados na Fase 5

---

## 🎯 PRÓXIMOS PASSOS

### **Investigar Pendente:**
1. **Estrutura completa** da tabela `levels`
2. **Relacionamentos** completos (foreign keys)
3. **Índices** existentes
4. **Contadores** de registros por tabela

### **Documentar:**
1. **Triggers ativos** por tabela
2. **Funções** existentes
3. **Políticas RLS** ativas

---

**📌 ESTA É A ESTRUTURA REAL EXTRAÍDA DO BANCO!**  
**📌 SEMPRE CONSULTE ESTE ARQUIVO PARA ESTRUTURA CORRETA!**

