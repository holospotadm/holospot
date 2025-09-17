# 🔧 FUNÇÕES DO HOLOSPOT

## 📊 **ESTATÍSTICAS**
- **Total:** 116 funções
- **Extração:** 2025-09-17 02:21:37
- **Fonte:** Banco Supabase (produção)

## 📁 **ORGANIZAÇÃO POR CATEGORIA**

### 🎮 **Gamification (7 funções)**
**Arquivo:** `gamification_functions.sql`

Funções relacionadas ao sistema de gamificação:
- Cálculo de níveis
- Ranking global
- Dados de gamificação
- Pontos e progressão

### 🔔 **Notifications (9 funções)**
**Arquivo:** `notifications_functions.sql`

Sistema completo de notificações:
- Criação de notificações
- Agrupamento inteligente
- Anti-spam
- Limpeza automática

### 🔥 **Streak (4 funções)**
**Arquivo:** `streak_functions.sql`

Sistema de streaks de engajamento:
- Cálculo de streaks
- Atualização automática
- Dados de streak
- Milestones

### 🏆 **Badges (5 funções)**
**Arquivo:** `badges_functions.sql`

Sistema de emblemas e conquistas:
- Verificação automática
- Notificações de badges
- Bônus de pontos
- Concessão de emblemas

### 🛠️ **Utility (2 funções)**
**Arquivo:** `utility_functions.sql`

Funções auxiliares do sistema:
- Atualização de timestamps
- Geração de usernames

### 🧪 **Testing (1 função)**
**Arquivo:** `testing_functions.sql`

Funções de teste e debug:
- Criação de dados de teste

## 🔍 **FUNÇÕES PRINCIPAIS**

### **Sistema de Pontos:**
- `update_user_total_points()` - Atualiza pontos totais
- `add_points_secure()` - Adiciona pontos com segurança
- `calculate_user_level()` - Calcula nível baseado em pontos

### **Sistema de Notificações:**
- `create_single_notification()` - Cria notificação única
- `handle_level_up_notification()` - Notifica level-up
- `auto_group_recent_notifications()` - Agrupa notificações

### **Sistema de Streak:**
- `calculate_user_streak()` - Calcula streak atual
- `update_user_streak()` - Atualiza streak do usuário
- `apply_streak_bonus_retroactive()` - Aplica bônus retroativo

### **Sistema de Badges:**
- `auto_check_badges_with_bonus_after_action()` - Verifica badges automaticamente
- `check_and_grant_badges_with_bonus()` - Concede badges com bônus

## ⚠️ **FUNÇÕES CRÍTICAS**

Estas funções são essenciais para o funcionamento do sistema:

1. **`update_user_total_points()`** - Atualiza pontos e levels
2. **`handle_level_up_notification()`** - Notificações de level-up
3. **`update_user_streak_trigger()`** - Atualização automática de streaks
4. **`auto_check_badges_with_bonus_after_action()`** - Sistema de badges

## 🔄 **SINCRONIZAÇÃO**

**Status:** ✅ Sincronizado com banco real
**Última verificação:** 2025-09-17 02:21:37
**Próxima verificação:** Recomendada em 1 semana

