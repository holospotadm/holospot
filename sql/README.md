# Estrutura SQL do HoloSpot

Este diretório contém toda a estrutura do banco de dados do **HoloSpot**, uma plataforma de reconhecimento e valorização de pessoas. O banco de dados é hospedado no **Supabase** (PostgreSQL).

---

## Sobre o HoloSpot

O HoloSpot é uma rede social focada em **reconhecimento positivo**, onde usuários podem:
- Criar posts destacando pessoas (holofotes)
- Reagir a posts com emoções (❤️ Amei, 👏 Palmas, 🫂 Abraço)
- Dar feedbacks construtivos
- Participar de comunidades
- Participar de correntes de reconhecimento (chains)
- Acumular pontos e subir de nível (gamificação)
- Conquistar badges por ações específicas
- Manter streaks de engajamento diário

---

## Estrutura de Diretórios

```
sql/
├── schema/          # Definições de tabelas (CREATE TABLE)
├── functions/       # Funções PL/pgSQL (1 arquivo por função)
├── triggers/        # Triggers agrupados por tabela
├── constraints/     # Constraints agrupados por tabela
├── policies/        # Policies RLS agrupadas por tabela
└── migrations/      # Migrações incrementais
```

---

## Tabelas do Sistema

O sistema possui **21 tabelas** organizadas em módulos funcionais:

### Módulo Principal (Core)

| Tabela | Descrição |
|--------|-----------|
| `profiles` | Perfis de usuários (nome, username, avatar, configurações) |
| `posts` | Posts/holofotes criados pelos usuários |
| `comments` | Comentários em posts |
| `reactions` | Reações em posts (loved, claps, hug) |
| `feedbacks` | Feedbacks construtivos em posts |
| `follows` | Relacionamentos de seguir entre usuários |

### Módulo de Comunidades

| Tabela | Descrição |
|--------|-----------|
| `communities` | Comunidades/grupos do sistema |
| `community_members` | Membros de cada comunidade (com roles) |

### Módulo de Correntes (Chains)

| Tabela | Descrição |
|--------|-----------|
| `chains` | Correntes de reconhecimento |
| `chain_posts` | Posts participantes de cada corrente |

### Módulo de Gamificação

| Tabela | Descrição |
|--------|-----------|
| `levels` | Níveis do sistema (1-10) com pontos necessários |
| `badges` | Badges/conquistas disponíveis |
| `user_badges` | Badges conquistados por cada usuário |
| `user_points` | Pontos totais e nível atual de cada usuário |
| `user_streaks` | Streaks de engajamento diário |
| `points_history` | Histórico detalhado de pontos ganhos |

### Módulo de Comunicação

| Tabela | Descrição |
|--------|-----------|
| `conversations` | Conversas privadas entre usuários |
| `messages` | Mensagens das conversas |
| `notifications` | Notificações do sistema |

### Módulo de Acesso

| Tabela | Descrição |
|--------|-----------|
| `invites` | Códigos de convite para novos usuários |
| `waitlist` | Lista de espera para acesso |

---

## Sistema de Pontuação

O HoloSpot possui um sistema de gamificação baseado em pontos:

| Ação | Pontos |
|------|--------|
| Criar post | +10 pts |
| Receber reação | +2 pts |
| Dar reação | +3 pts |
| Receber comentário | +3 pts |
| Dar comentário | +5 pts |
| Receber feedback | +5 pts |
| Dar feedback | +7 pts |
| Participar de corrente | +15 pts |

### Níveis

| Nível | Nome | Pontos Necessários |
|-------|------|-------------------|
| 1 | Iniciante | 0 |
| 2 | Observador | 50 |
| 3 | Participante | 150 |
| 4 | Colaborador | 300 |
| 5 | Engajado | 500 |
| 6 | Influenciador | 800 |
| 7 | Líder | 1200 |
| 8 | Mentor | 1800 |
| 9 | Embaixador | 2500 |
| 10 | Lenda | 3500 |

---

## Tipos de Reações

As reações disponíveis nos posts são:

| Tipo | Emoji | Descrição |
|------|-------|-----------|
| `loved` | ❤️ | Amei |
| `claps` | 👏 | Palmas |
| `hug` | 🫂 | Abraço |

---

## Funções Principais

O sistema possui **158 funções** PL/pgSQL. As principais são:

### Gamificação
- `add_points_to_user` - Adiciona pontos ao usuário
- `calculate_user_level` - Calcula nível baseado em pontos
- `check_and_award_badges` - Verifica e concede badges
- `calculate_holospot_index` - Calcula índice de engajamento

### Streaks
- `update_user_streak` - Atualiza streak do usuário
- `get_user_streak` - Retorna streak atual
- `calculate_streak_bonus` - Calcula bônus por streak

### Correntes
- `create_chain` - Cria nova corrente
- `add_post_to_chain` - Adiciona post à corrente
- `get_chain_participants` - Lista participantes

### Notificações
- `create_notification_smart` - Cria notificação com anti-spam
- `handle_reaction_simple` - Notifica reação recebida
- `notify_level_up` - Notifica subida de nível

### Comunidades
- `add_community_member` - Adiciona membro à comunidade
- `remove_community_member` - Remove membro

---

## Triggers por Tabela

Os triggers automatizam ações no banco:

### posts (5 triggers)
- Verificação de badges após criar post
- Pontuação automática
- Atualização de métricas

### reactions (6 triggers)
- Pontuação para quem reage e quem recebe
- Notificação automática
- Verificação de badges

### comments (5 triggers)
- Pontuação automática
- Notificação ao autor do post
- Verificação de badges

### feedbacks (4 triggers)
- Pontuação automática
- Notificação ao mencionado

### user_points (3 triggers)
- Verificação de level up
- Notificação de nível
- Atualização de badges

---

## Policies (RLS)

O sistema usa **Row Level Security** para controle de acesso. Cada tabela tem policies específicas para:

- **SELECT**: Quem pode ler os dados
- **INSERT**: Quem pode criar registros
- **UPDATE**: Quem pode atualizar
- **DELETE**: Quem pode deletar

Exemplo: Um usuário só pode deletar seus próprios posts, mas pode ler posts de todos.

---

## Convenções de Nomenclatura

### Schema (Tabelas)
- Formato: `NN_nome_tabela.sql` (NN = número sequencial alfabético)
- Exemplo: `01_badges.sql`, `15_posts.sql`, `16_profiles.sql`

### Functions
- Formato: `nome_funcao.sql`
- Funções com overload (mesma função, parâmetros diferentes): `nome_funcao_v2.sql`, `nome_funcao_v3.sql`

### Triggers
- Formato: `nome_tabela_triggers.sql`
- Contém todos os triggers de uma tabela em um único arquivo

### Constraints
- Formato: `nome_tabela_constraints.sql`
- Contém PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK de cada tabela

### Policies
- Formato: `nome_tabela_policies.sql`
- Contém todas as policies RLS de cada tabela

---

## Como Fazer Alterações

### 1. Alteração Simples (ex: modificar uma função)

1. Edite o arquivo correspondente em `functions/nome_funcao.sql`
2. Execute o SQL no **Supabase SQL Editor**
3. Faça commit no GitHub

### 2. Nova Migração (alteração estrutural)

1. Crie arquivo em `migrations/YYYYMMDD_descricao.sql`
2. Escreva o SQL da alteração incremental
3. Execute no Supabase
4. **IMPORTANTE**: Atualize também o arquivo principal correspondente
   - Se alterou função → atualize `functions/nome_funcao.sql`
   - Se alterou trigger → atualize `triggers/tabela_triggers.sql`
   - Se alterou constraint → atualize `constraints/tabela_constraints.sql`
5. Faça commit de tudo no GitHub

### 3. Extrair Estado Atual do Banco

Se precisar sincronizar o GitHub com o banco, use estas queries no Supabase:

**Funções:**
```sql
SELECT pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;
```

**Triggers:**
```sql
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public';
```

**Constraints:**
```sql
SELECT tc.table_name, tc.constraint_name, tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public';
```

---

## Diagrama de Relacionamentos

```
profiles ─────────────────────────────────────────────────────┐
    │                                                         │
    ├──< posts (user_id, mentioned_user_id)                   │
    │       │                                                 │
    │       ├──< reactions (post_id, user_id)                 │
    │       ├──< comments (post_id, user_id)                  │
    │       ├──< feedbacks (post_id, author_id)               │
    │       └──< chain_posts (post_id, author_id)             │
    │                   │                                     │
    │                   └──> chains (creator_id)              │
    │                                                         │
    ├──< follows (follower_id, following_id)                  │
    │                                                         │
    ├──< user_points (user_id) ──> levels (level_id)          │
    ├──< user_badges (user_id) ──> badges (badge_id)          │
    ├──< user_streaks (user_id)                               │
    ├──< points_history (user_id)                             │
    │                                                         │
    ├──< notifications (user_id, from_user_id)                │
    │                                                         │
    ├──< conversations (user1_id, user2_id)                   │
    │       └──< messages (conversation_id, sender_id)        │
    │                                                         │
    ├──< community_members (user_id)                          │
    │       └──> communities (owner_id)                       │
    │                                                         │
    └──< invites (created_by, used_by)                        │
```

---

## Última Atualização

Extraído do banco de dados Supabase em: **2025-12-29**

**Estatísticas:**
- 21 tabelas
- 158 funções
- 32 triggers
- 138 constraints
- 83 policies RLS
