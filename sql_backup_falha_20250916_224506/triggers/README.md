# ⚡ TRIGGERS DO HOLOSPOT

## 📊 **ESTATÍSTICAS**
- **Total:** 28 triggers
- **Extração:** 2025-09-17 02:21:37
- **Fonte:** Banco Supabase (produção)

## 📁 **ORGANIZAÇÃO POR TABELA**

### 💬 **Comments (6 triggers)**
**Arquivo:** `comments_triggers.sql`

- `auto_badge_check_bonus_comments` - Verifica badges após comentário
- `comment_delete_secure_trigger` - Segurança na exclusão
- `comment_insert_secure_trigger` - Segurança na inserção
- `comment_notification_correto_trigger` - Notificações de comentário
- `comment_notify_only_trigger` - Notificações simples
- `update_streak_after_comment` - Atualiza streak após comentário

### 👍 **Reactions (6 triggers)**
**Arquivo:** `reactions_triggers.sql`

- `auto_badge_check_bonus_reactions` - Verifica badges após reação
- `reaction_delete_secure_trigger` - Segurança na exclusão
- `reaction_insert_secure_trigger` - **DISABLED** - Inserção segura
- `reaction_notification_simple_trigger` - Notificações de reação
- `reaction_points_simple_trigger` - Pontos por reação
- `update_streak_after_reaction` - Atualiza streak após reação

### 📝 **Feedbacks (4 triggers)**
**Arquivo:** `feedbacks_triggers.sql`

- `auto_badge_check_bonus_feedbacks` - Verifica badges após feedback
- `feedback_insert_secure_trigger` - Segurança na inserção
- `feedback_notification_correto_trigger` - Notificações de feedback
- `update_streak_after_feedback` - Atualiza streak após feedback

### 📄 **Posts (4 triggers)**
**Arquivo:** `posts_triggers.sql`

- `auto_badge_check_bonus_posts` - Verifica badges após post
- `holofote_notification_trigger` - Notificações de holofote
- `post_insert_secure_trigger` - Segurança na inserção
- `update_streak_after_post` - Atualiza streak após post

### 🎯 **User Points (3 triggers)**
**Arquivo:** `user_points_triggers.sql`

- `auto_badge_check_bonus_user_points` - Verifica badges após pontos
- `level_up_notification_trigger` - **CRÍTICO** - Notificações de level-up
- `update_user_points_updated_at` - Atualiza timestamp

### 🏆 **User Badges (1 trigger)**
**Arquivo:** `user_badges_triggers.sql`

- `badge_notify_only_trigger` - Notificações de badges

### 🔥 **User Streaks (1 trigger)**
**Arquivo:** `user_streaks_triggers.sql`

- `streak_notify_only_trigger` - Notificações de streak

### 👥 **Follows (1 trigger)**
**Arquivo:** `follows_triggers.sql`

- `follow_notification_correto_trigger` - Notificações de follow

### 👤 **Profiles (1 trigger)**
**Arquivo:** `profiles_triggers.sql`

- `trigger_generate_username` - Gera username automático

### 🏅 **Badges (1 trigger)**
**Arquivo:** `badges_triggers.sql`

- `update_badges_updated_at` - Atualiza timestamp

## 🔥 **TRIGGERS CRÍTICOS**

### **Sistema de Gamificação:**
1. **`level_up_notification_trigger`** - Notifica quando usuário sobe de nível
2. **`update_streak_after_*`** - Atualiza streaks automaticamente (4 triggers)
3. **`auto_badge_check_bonus_*`** - Verifica badges automaticamente (5 triggers)

### **Sistema de Pontos:**
1. **`reaction_points_simple_trigger`** - Adiciona pontos por reações
2. **`*_insert_secure_trigger`** - Adiciona pontos por ações (4 triggers)

### **Sistema de Notificações:**
1. **`*_notification_*_trigger`** - Cria notificações (6 triggers)

## ⚠️ **TRIGGERS DESABILITADOS**

- **`reaction_insert_secure_trigger`** - **DISABLED**
  - **Motivo:** Duplicação com `reaction_points_simple_trigger`
  - **Status:** Desabilitado para evitar pontos duplicados

## 🔄 **FLUXO DE TRIGGERS**

### **Quando usuário faz uma ação:**
1. **Inserção** → `*_insert_secure_trigger` → Adiciona pontos
2. **Pontos** → `update_user_total_points()` → Atualiza total e level
3. **Level** → `level_up_notification_trigger` → Notifica se subiu
4. **Badges** → `auto_badge_check_bonus_*` → Verifica novos badges
5. **Streak** → `update_streak_after_*` → Atualiza streak
6. **Notificação** → `*_notification_*_trigger` → Notifica outros usuários

## 🔄 **SINCRONIZAÇÃO**

**Status:** ✅ Sincronizado com banco real
**Última verificação:** 2025-09-17 02:21:37
**Próxima verificação:** Recomendada em 1 semana

