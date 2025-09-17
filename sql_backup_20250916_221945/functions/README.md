# 🔧 FUNCTIONS - Sistema de Funções do HoloSpot

## 📋 Visão Geral

Este diretório contém todas as **18 funções** utilizadas pelos triggers do sistema HoloSpot, organizadas por categoria e funcionalidade. Todas as funções são **SECURITY INVOKER** e escritas em **PL/pgSQL**.

## 📊 Estatísticas

- **Total de Funções:** 18
- **Segurança:** 18 SECURITY INVOKER (0 DEFINER)
- **Linguagem:** 18 PL/pgSQL (0 SQL puro)
- **Tipo:** 18 TRIGGER functions
- **Volatilidade:** 18 VOLATILE

## 📁 Organização dos Arquivos

### **01_audit_functions.sql** - Funções de Auditoria
- **1 função** para manutenção de campos `updated_at`
- **Função:** `update_updated_at_column()`
- **Uso:** Triggers de auditoria em `badges` e `user_points`

### **02_gamification_functions.sql** - Funções de Gamificação
- **1 função** para verificação automática de badges
- **Função:** `auto_check_badges_with_bonus_after_action()`
- **Uso:** Todos os triggers de gamificação (5 triggers)

### **03_notification_functions.sql** - Funções de Notificação
- **7 funções** especializadas por tipo de notificação
- **Sistema anti-spam** com janelas de tempo
- **Mensagens padronizadas** sem exclamações desnecessárias

### **04_security_functions.sql** - Funções de Segurança
- **7 funções** para operações seguras e pontuação
- **Sistema integrado** de gerenciamento de pontos
- **Validações** e prevenção de fraudes

### **05_utility_functions.sql** - Funções Utilitárias
- **1 função** para geração automática de username
- **Função:** `generate_username_from_email()`
- **Uso:** Trigger utilitário em `profiles`

## 📈 Funções por Categoria

| Categoria | Quantidade | Principais Responsabilidades |
|-----------|------------|------------------------------|
| **NOTIFICATION** | 7 | Criação automática de notificações |
| **SECURITY** | 7 | Operações seguras e pontuação |
| **GAMIFICATION** | 1 | Verificação automática de badges |
| **AUDIT** | 1 | Manutenção de timestamps |
| **UTILITY** | 1 | Geração de username |

## 🔄 Fluxo de Dependências

### **Funções Principais (Implementadas)**
```
update_updated_at_column()
├── Usada por: update_badges_updated_at
└── Usada por: update_user_points_updated_at

auto_check_badges_with_bonus_after_action()
├── Usada por: auto_badge_check_bonus_posts
├── Usada por: auto_badge_check_bonus_comments
├── Usada por: auto_badge_check_bonus_reactions
├── Usada por: auto_badge_check_bonus_feedbacks
└── Usada por: auto_badge_check_bonus_user_points

generate_username_from_email()
└── Usada por: trigger_generate_username
```

### **Funções Dependentes (Devem Existir)**
```
check_and_grant_badges_with_bonus()
├── Chamada por: auto_check_badges_with_bonus_after_action()
└── Responsável pela lógica específica de badges

create_single_notification()
├── Chamada por: handle_comment_notification_only()
├── Chamada por: handle_reaction_simple()
└── Chamada por: handle_badge_notification_only()

notify_streak_milestone_correct()
└── Chamada por: handle_streak_notification_only()

update_user_total_points()
├── Chamada por: handle_post_insert_secure()
├── Chamada por: handle_comment_insert_secure()
├── Chamada por: handle_feedback_insert_secure()
└── Chamada por: handle_reaction_points_simple()

add_points_secure()
├── Chamada por: handle_reaction_insert_secure()
└── Responsável por adicionar pontos com validações

delete_comment_points_secure()
├── Chamada por: handle_comment_delete_secure()
└── Remove pontos de comentários (SECURITY DEFINER)

delete_reaction_points_secure()
├── Chamada por: handle_reaction_delete_secure()
└── Remove pontos de reações (SECURITY DEFINER)

recalculate_user_points_secure()
├── Chamada por: handle_comment_delete_secure()
├── Chamada por: handle_reaction_delete_secure()
└── Recalcula totais de usuários (SECURITY DEFINER)
```

## 🎯 Sistema de Pontuação

### **Valores de Pontos por Ação**
| Ação | Quem Ganha | Pontos | Função Responsável |
|------|------------|--------|-------------------|
| **Criar Post** | Autor | +10 | `handle_post_insert_secure` |
| **Ser Mencionado** | Mencionado | +5 | `handle_post_insert_secure` |
| **Criar Comentário** | Autor | +5 | `handle_comment_insert_secure` |
| **Receber Comentário** | Autor Post | +3 | `handle_comment_insert_secure` |
| **Dar Reação** | Quem Reage | +3 | `handle_reaction_*_secure` |
| **Receber Reação** | Autor Post | +2 | `handle_reaction_*_secure` |
| **Dar Feedback** | Quem Dá | +8 | `handle_feedback_insert_secure` |
| **Receber Feedback** | Quem Recebe | +5 | `handle_feedback_insert_secure` |

### **Tipos de Ação no Histórico**
- `post_created` - Criação de posts
- `mentioned_in_post` - Menção em posts
- `comment_created` - Criação de comentários
- `comment_received` - Recebimento de comentários
- `reaction_given` - Reações dadas
- `reaction_received` - Reações recebidas
- `feedback_given` - Feedbacks dados
- `feedback_received` - Feedbacks recebidos

## 🔔 Sistema de Notificações

### **Tipos e Janelas Anti-Spam**
| Tipo | Janela | Prioridade | Função Responsável |
|------|--------|------------|-------------------|
| **mention** | 1 hora | 3 (alta) | `handle_holofote_notification` |
| **comment** | 6 horas | 2 (média) | `handle_comment_notification_*` |
| **reaction** | imediato | 1 (baixa) | `handle_reaction_simple` |
| **feedback** | 24 horas | 2 (média) | `handle_feedback_notification_correto` |
| **follow** | 24 horas | 2 (média) | `handle_follow_notification_correto` |
| **badge_earned** | imediato | 3 (alta) | `handle_badge_notification_only` |
| **streak** | imediato | 3 (alta) | `handle_streak_notification_only` |

### **Mensagens Padronizadas**
- ✅ **Sem exclamações** desnecessárias
- ✅ **Linguagem natural** e amigável
- ✅ **Informações específicas** quando relevante
- ✅ **Emojis apropriados** por contexto

## 🚀 Deployment

### **Ordem de Criação**
1. **Funções Independentes** (audit, utility)
2. **Funções de Segurança** (com dependências DEFINER)
3. **Funções de Notificação** (com dependências auxiliares)
4. **Funções de Gamificação** (com dependências de badges)
5. **Triggers** (após todas as funções)

### **Dependências Externas Necessárias**
```sql
-- Funções SECURITY DEFINER (devem ser criadas primeiro)
CREATE FUNCTION check_and_grant_badges_with_bonus(UUID) RETURNS TEXT;
CREATE FUNCTION create_single_notification(UUID, UUID, TEXT, TEXT, INTEGER) RETURNS VOID;
CREATE FUNCTION notify_streak_milestone_correct(UUID, INTEGER, INTEGER) RETURNS VOID;
CREATE FUNCTION update_user_total_points(UUID) RETURNS VOID;
CREATE FUNCTION add_points_secure(UUID, INTEGER, TEXT, UUID, TEXT, UUID, TEXT) RETURNS VOID;
CREATE FUNCTION delete_comment_points_secure(UUID) RETURNS VOID;
CREATE FUNCTION delete_reaction_points_secure(UUID) RETURNS VOID;
CREATE FUNCTION recalculate_user_points_secure(UUID) RETURNS VOID;
```

### **Verificação de Deployment**
```sql
-- Verificar funções criadas
SELECT proname, prosecdef, provolatile, lanname
FROM pg_proc p
JOIN pg_language l ON p.prolang = l.oid
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND proname IN (
    'update_updated_at_column',
    'auto_check_badges_with_bonus_after_action',
    'handle_holofote_notification',
    'handle_comment_notification_correto',
    'handle_comment_notification_only',
    'handle_reaction_simple',
    'handle_feedback_notification_correto',
    'handle_follow_notification_correto',
    'handle_badge_notification_only',
    'handle_streak_notification_only',
    'handle_post_insert_secure',
    'handle_comment_insert_secure',
    'handle_comment_delete_secure',
    'handle_reaction_insert_secure',
    'handle_reaction_delete_secure',
    'handle_reaction_points_simple',
    'handle_feedback_insert_secure',
    'generate_username_from_email'
)
ORDER BY proname;
```

## 🔧 Manutenção

### **Monitoramento**
- Verificar logs de erro das funções
- Monitorar performance das operações
- Validar integridade dos pontos
- Acompanhar criação de notificações

### **Troubleshooting**
- Funções com muitas execuções podem impactar performance
- Verificar se funções dependentes existem
- Monitorar locks em operações concorrentes
- Validar dados de entrada

### **Atualizações**
- Sempre testar em ambiente de desenvolvimento
- Fazer backup antes de modificações
- Documentar mudanças no CHANGELOG
- Verificar compatibilidade com triggers

---

**📅 Última Atualização:** Setembro 2025  
**🔄 Status:** Todas as funções extraídas e organizadas  
**📊 Cobertura:** 18/18 funções dos triggers (100%)  
**🎯 Próximo:** Extrair funções dependentes e policies RLS

