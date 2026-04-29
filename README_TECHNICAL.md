# HoloSpot - Documentação Técnica Completa

**Autor:** Manus AI  
**Data:** 06 de abril de 2026  
**Versão:** v13.0-autonomous  
**Propósito:** Documentação técnica completa para desenvolvedores que precisam entender, manter ou expandir a plataforma HoloSpot

---

## Índice

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitetura do Backend](#3-arquitetura-do-backend)
4. [Banco de Dados Completo](#4-banco-de-dados-completo)
5. [Funções SQL (166 funções)](#5-funções-sql-166-funções)
6. [Triggers (32 triggers)](#6-triggers-32-triggers)
7. [Arquitetura do Frontend](#7-arquitetura-do-frontend)
8. [Segurança e RLS](#8-segurança-e-rls)
9. [Fluxos de Dados Detalhados](#9-fluxos-de-dados-detalhados)
10. [Deploy e CI/CD](#10-deploy-e-cicd)
11. [Debugging e Troubleshooting](#11-debugging-e-troubleshooting)

> **Nota:** As seções 4.7, 4.8 e 4.9 cobrem as funcionalidades mais recentes: Correntes (Chains), Feed Memórias Vivas e Tour de Onboarding.

---

## 1. Visão Geral da Arquitetura

O HoloSpot é construído sobre uma arquitetura **Jamstack** moderna que combina:
- Um frontend estático (HTML/CSS/JS) hospedado na Vercel
- Um backend "serverless" gerenciado pelo Supabase (PostgreSQL + APIs auto-geradas)
- Lógica de negócio centralizada no banco de dados via triggers e funções PostgreSQL

### 1.1. Filosofia Arquitetural: "Lógica no Banco"

Diferentemente de arquiteturas tradicionais onde a lógica de negócio reside em um servidor de aplicação (Node.js, Python, etc.), o HoloSpot implementa essa lógica **diretamente no PostgreSQL**.

**Como funciona:**
1. O frontend chama a API REST do Supabase para operações básicas (INSERT, UPDATE, DELETE, SELECT)
2. O PostgreSQL intercepta essas operações através de **triggers**
3. Os triggers chamam **funções plpgsql** que contêm a lógica de negócio
4. As funções executam operações complexas (conceder pontos, verificar badges, criar notificações)
5. As mudanças são propagadas em tempo real via Supabase Realtime

**Vantagens:**
- **Consistência garantida:** A lógica é aplicada no nível do banco, impossível de burlar
- **Segurança centralizada:** RLS (Row Level Security) protege dados no nível mais baixo
- **Frontend agnóstico:** Qualquer cliente (web, mobile, desktop) pode se conectar
- **Auditabilidade:** Todas as operações são rastreáveis no banco

**Desvantagens:**
- **Curva de aprendizado:** Requer conhecimento profundo de SQL e plpgsql
- **Debugging complexo:** Erros em triggers podem ser difíceis de rastrear
- **Menor flexibilidade:** Mudanças rápidas exigem alterações no schema do banco

### 1.2. Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                        USUÁRIO                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   VERCEL (CDN Global)                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              index.html (~21.000+ linhas)              │   │
│  │  HTML + CSS + JavaScript (SPA)                       │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE (BaaS)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Supabase Client Library                 │   │
│  │  - REST API (auto-gerada)                            │   │
│  │  - Realtime (WebSockets)                             │   │
│  │  - Auth (autenticação)                               │   │
│  │  - Storage (armazenamento de arquivos)               │   │
│  └────────────────────┬─────────────────────────────────┘   │
│                       │                                      │
│                       ▼                                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            PostgreSQL 14+                            │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  21 Tabelas                                    │  │   │
│  │  │  166 Funções (plpgsql)                         │  │   │
│  │  │  32 Triggers                                   │  │   │
│  │  │  RLS (Row Level Security) em todas as tabelas │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Stack Tecnológico

### 2.1. Frontend

| Tecnologia | Versão | Propósito |
|:---|:---|:---|
| **HTML5** | - | Estrutura da aplicação |
| **CSS3** | - | Estilização (Flexbox, Grid, Gradientes, Backdrop Filter) |
| **JavaScript** | ES6+ | Lógica do cliente (procedural + classes) |
| **Supabase JS** | 2.x | Cliente oficial para interagir com Supabase |
| **Chart.js** | 4.x | Visualização de dados (gráficos de métricas) |
| **Shepherd.js** | 11.x | Tour de onboarding guiado para novos usuários |
| **Google Analytics** | GA4 | Tracking de eventos |

### 2.2. Backend

| Tecnologia | Versão | Propósito |
|:---|:---|:---|
| **PostgreSQL** | 14+ | Banco de dados relacional |
| **Supabase** | - | Backend-as-a-Service (BaaS) |
| **plpgsql** | - | Linguagem para funções e triggers |
| **PostgREST** | - | API REST auto-gerada (via Supabase) |
| **Realtime** | - | WebSockets para atualizações em tempo real |

### 2.3. Infraestrutura

| Serviço | Provedor | Propósito |
|:---|:---|:---|
| **Hospedagem Frontend** | Vercel | Servir `index.html` via CDN global |
| **Hospedagem Backend** | Supabase Cloud | Banco de dados, APIs, autenticação, storage |
| **Controle de Versão** | GitHub | Repositório de código-fonte |
| **CI/CD** | Vercel (automático) | Deploy automático ao fazer push para `main` |

### 2.4. Ferramentas de Desenvolvimento

| Ferramenta | Propósito |
|:---|:---|
| **Git** | Controle de versão |
| **Supabase Dashboard** | Gerenciamento do banco de dados, execução de SQL |
| **Browser DevTools** | Debugging do frontend |
| **PostgreSQL Logs** | Debugging de triggers e funções |

---

## 3. Arquitetura do Backend

O backend é 100% gerenciado pelo Supabase, que fornece:

### 3.1. PostgreSQL Gerenciado

- **Versão:** PostgreSQL 14+
- **Extensões Ativadas:**
  - `uuid-ossp`: Geração de UUIDs
  - `pg_trgm`: Busca textual avançada
  - `pgcrypto`: Funções criptográficas
- **Schema:** `public` (padrão)

### 3.2. API REST Auto-gerada (PostgREST)

O Supabase gera automaticamente uma API RESTful para todas as tabelas do banco, respeitando as políticas de RLS.

**Endpoints Gerados:**
- `GET /rest/v1/posts` - Lista posts
- `POST /rest/v1/posts` - Cria post
- `PATCH /rest/v1/posts?id=eq.{id}` - Atualiza post
- `DELETE /rest/v1/posts?id=eq.{id}` - Deleta post
- `POST /rest/v1/rpc/create_community` - Chama função SQL

**Autenticação:**
- Todas as requisições incluem um token JWT no header `Authorization: Bearer <token>`
- O token contém o `user_id` que é usado nas políticas de RLS (`auth.uid()`)

### 3.3. Supabase Realtime (WebSockets)

Permite que o frontend se inscreva a mudanças no banco de dados em tempo real.

**Exemplo de Inscrição:**
```javascript
const subscription = supabase
  .channel('public:posts')
  .on('postgres_changes', { 
    event: 'INSERT', 
    schema: 'public', 
    table: 'posts' 
  }, payload => {
    console.log('Novo post!', payload.new);
    // Adiciona post ao feed sem reload
  })
  .subscribe();
```

**Eventos Suportados:**
- `INSERT`: Quando um novo registro é criado
- `UPDATE`: Quando um registro é atualizado
- `DELETE`: Quando um registro é deletado

### 3.4. Supabase Auth

Gerencia autenticação de usuários.

**Tabelas:**
- `auth.users`: Tabela interna do Supabase com dados de autenticação
- `public.profiles`: Tabela pública sincronizada com `auth.users`

**Métodos de Autenticação:**
- Email + Senha
- Magic Link (email sem senha)
- OAuth (Google, GitHub, etc.) - configurável

**Fluxo de Autenticação:**
1. Usuário se cadastra via `supabase.auth.signUp()`
2. Supabase cria registro em `auth.users`
3. Trigger `handle_new_user` cria registro correspondente em `public.profiles`
4. Frontend recebe token JWT
5. Token é usado em todas as requisições subsequentes

### 3.5. Supabase Storage

Armazena arquivos (imagens de perfil, fotos de posts).

**Buckets:**
- `avatars`: Fotos de perfil dos usuários
- `post-images`: Fotos anexadas aos posts

**Fluxo de Upload:**
1. Frontend faz upload via `supabase.storage.from('avatars').upload()`
2. Supabase retorna URL pública do arquivo
3. Frontend armazena apenas a URL no banco (`avatar_url`, `photo_url`)

---

## 4. Banco de Dados Completo

O banco de dados é composto por **21 tabelas** organizadas em 5 grupos funcionais.

### 4.1. Grupo: Usuários e Perfis

#### Tabela: `profiles`

Armazena dados públicos dos usuários.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | - | ID único (sincronizado com `auth.users.id`) |
| `email` | TEXT | ✅ | - | Email do usuário |
| `name` | TEXT | ✅ | - | Nome completo |
| `avatar_url` | TEXT | ✅ | - | URL da foto de perfil |
| `username` | VARCHAR(50) | ✅ | - | Username único para menções (@username) |
| `timezone` | TEXT | ✅ | 'America/Sao_Paulo' | Fuso horário para cálculo de streaks |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação do perfil |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última atualização |
| `birth_date` | DATE | ✅ | - | Data de nascimento do usuário |
| `has_completed_onboarding` | BOOLEAN | ❌ | false | Indica se o usuário já completou (ou pulou) o tour de onboarding inicial |
| `bio` | TEXT | ✅ | - | Texto de apresentação do usuário exibido no perfil |

**Constraints:**
- `UNIQUE(email)`
- `UNIQUE(username)`

**Índices:**
- `idx_profiles_email` em `email`
- `idx_profiles_username` em `username`
- `idx_profiles_name` em `to_tsvector('portuguese', name)` (busca textual)
- `idx_profiles_created_at` em `created_at DESC`
- `idx_profiles_timezone` em `timezone`

**Triggers:**
- `trigger_generate_username`: Gera username automaticamente baseado no email

**Relacionamentos:**
- Referenciada por: `posts`, `comments`, `reactions`, `follows`, `notifications`, `user_badges`, `user_points`, `user_streaks`, `points_history`, `communities`, `community_members`

---

### 4.2. Grupo: Conteúdo e Interações

#### Tabela: `posts`

Armazena todos os posts de reconhecimento ("holofotes").

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único do post |
| `user_id` | UUID | ❌ | - | ID do autor (FK para `profiles.id`) |
| `celebrated_person_name` | TEXT | ❌ | - | @username da pessoa destacada |
| `content` | TEXT | ❌ | - | Conteúdo do post |
| `type` | TEXT | ❌ | - | Tipo: 'gratitude', 'achievement', 'memory', 'inspiration', 'support', 'admiration' |
| `photo_url` | TEXT | ✅ | - | URL da foto anexada (opcional) |
| `community_id` | UUID | ✅ | - | ID da comunidade (NULL = post global) |
| `mentioned_user_id` | UUID | ✅ | - | ID do usuário mencionado (necessário para "Holofotes Recebidos") |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última atualização |

**Constraints:**
- `CHECK (type IN ('gratitude', 'achievement', 'memory', 'inspiration', 'support', 'admiration'))`
- `CHECK (LENGTH(TRIM(content)) > 0)`

**Índices:**
- `idx_posts_user` em `user_id`
- `idx_posts_created_at` em `created_at DESC`
- `idx_posts_community` em `community_id` (WHERE `community_id IS NOT NULL`)

**Triggers:**
- `post_insert_secure_trigger`: Concede pontos após criação
- `auto_badge_check_bonus_posts`: Verifica badges após criação
- `holofote_notification_trigger`: Cria notificação para pessoa destacada
- `update_streak_after_post`: Atualiza streak do autor
- `trigger_award_first_community_post_badge`: Badge de primeiro post em comunidade

#### Tabela: `comments`

Armazena comentários feitos nos posts.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único do comentário |
| `post_id` | UUID | ❌ | - | ID do post (FK para `posts.id`) |
| `user_id` | UUID | ❌ | - | ID do autor do comentário |
| `content` | TEXT | ❌ | - | Conteúdo do comentário |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Constraints:**
- `CHECK (LENGTH(TRIM(content)) > 0)`

**Índices:**
- `idx_comments_post` em `post_id, created_at DESC`
- `idx_comments_user` em `user_id`

**Triggers:**
- `comment_insert_secure_trigger`: Concede pontos ao autor do post
- `auto_badge_check_bonus_comments`: Verifica badges
- `comment_notification_correto_trigger`: Notifica autor do post
- `update_streak_after_comment`: Atualiza streak
- `comment_delete_secure_trigger`: Remove pontos ao deletar

#### Tabela: `reactions`

Registra reações dadas aos posts.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único da reação |
| `post_id` | UUID | ❌ | - | ID do post |
| `user_id` | UUID | ❌ | - | ID do usuário que reagiu |
| `type` | TEXT | ❌ | - | Tipo de reação: `loved` (❤️), `claps` (👏), `hug` (🫂) |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Constraints:**
- `UNIQUE(post_id, user_id, type)` - Um usuário só pode dar uma reação de cada tipo por post
- `CHECK(type IN ('loved', 'claps', 'hug', 'touched', 'grateful', 'inspired'))` - Tipos válidos de reação

**Índices:**
- `idx_reactions_post` em `post_id`
- `idx_reactions_user` em `user_id`
- `idx_reactions_unique` em `(post_id, user_id)` (UNIQUE)

**Triggers:**
- `reaction_insert_secure_trigger`: Concede pontos ao autor do post
- `auto_badge_check_bonus_reactions`: Verifica badges
- `reaction_notification_simple_trigger`: Notifica autor do post
- `update_streak_after_reaction`: Atualiza streak
- `reaction_delete_secure_trigger`: Remove pontos ao deletar

#### Tabela: `feedbacks`

Armazena feedbacks dados nos posts (comentários mais elaborados).

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único do feedback |
| `post_id` | UUID | ❌ | - | ID do post |
| `user_id` | UUID | ❌ | - | ID do autor do feedback |
| `content` | TEXT | ❌ | - | Conteúdo do feedback |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Constraints:**
- `CHECK (LENGTH(TRIM(content)) > 0)`

**Índices:**
- `idx_feedbacks_post` em `post_id, created_at DESC`
- `idx_feedbacks_user` em `user_id`

**Triggers:**
- `feedback_insert_secure_trigger`: Concede pontos
- `auto_badge_check_bonus_feedbacks`: Verifica badges
- `feedback_notification_correto_trigger`: Notifica autor do post
- `update_streak_after_feedback`: Atualiza streak

---

### 4.3. Grupo: Social e Notificações

#### Tabela: `follows`

Relação de quem segue quem.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `follower_id` | UUID | ❌ | - | ID de quem segue |
| `following_id` | UUID | ❌ | - | ID de quem é seguido |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data em que começou a seguir |

**Constraints:**
- `UNIQUE(follower_id, following_id)`
- `CHECK (follower_id != following_id)` - Não pode seguir a si mesmo

**Índices:**
- `idx_follows_follower` em `follower_id`
- `idx_follows_following` em `following_id`
- `idx_follows_unique` em `(follower_id, following_id)` (UNIQUE)

**Triggers:**
- `follow_notification_correto_trigger`: Notifica quem foi seguido

#### Tabela: `notifications`

Armazena todas as notificações geradas para os usuários.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `user_id` | UUID | ❌ | - | ID do usuário que recebe a notificação |
| `from_user_id` | UUID | ✅ | - | ID do usuário que gerou a notificação |
| `type` | TEXT | ❌ | - | Tipo: 'holofote', 'reaction', 'comment', 'follow', 'badge', 'level_up', 'streak' |
| `message` | TEXT | ❌ | - | Mensagem da notificação |
| `reference_id` | TEXT | ✅ | - | ID de referência (ex: post_id, badge_name) |
| `is_read` | BOOLEAN | ✅ | FALSE | Se a notificação foi lida |
| `priority` | INTEGER | ✅ | 1 | Prioridade (1-5) |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Índices:**
- `idx_notifications_user` em `user_id, created_at DESC`
- `idx_notifications_unread` em `(user_id, is_read)` WHERE `is_read = FALSE`
- `idx_notifications_type` em `type`

**Triggers:**
- Nenhum (notificações são criadas por outras funções)

---

### 4.4. Grupo: Gamificação

#### Tabela: `user_points`

Armazena a pontuação total e o nível atual de cada usuário (cache).

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `user_id` | UUID | ❌ | - | ID do usuário (UNIQUE) |
| `total_points` | INTEGER | ✅ | 0 | Pontos totais acumulados |
| `current_level` | INTEGER | ✅ | 1 | Nível atual (1-10) |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última atualização |

**Constraints:**
- `UNIQUE(user_id)`
- `CHECK (total_points >= 0)`
- `CHECK (current_level >= 1 AND current_level <= 10)`

**Índices:**
- `idx_user_points_user` em `user_id` (UNIQUE)
- `idx_user_points_total` em `total_points DESC` (para rankings)

**Triggers:**
- `auto_badge_check_bonus_user_points`: Verifica badges após mudança de pontos
- `level_up_notification_trigger`: Notifica quando sobe de nível
- `update_user_points_updated_at`: Atualiza `updated_at`

#### Tabela: `points_history`

Log detalhado de todas as transações de pontos.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `user_id` | UUID | ❌ | - | ID do usuário |
| `points` | INTEGER | ❌ | - | Quantidade de pontos (positivo ou negativo) |
| `action_type` | TEXT | ❌ | - | Tipo de ação: 'post_created', 'reaction_received', etc. |
| `reference_id` | UUID | ✅ | - | ID de referência (ex: post_id) |
| `reference_type` | TEXT | ✅ | - | Tipo de referência: 'post', 'comment', 'reaction' |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data da transação |

**Índices:**
- `idx_points_history_user` em `user_id, created_at DESC`
- `idx_points_history_action` em `action_type`

**Triggers:**
- Nenhum (registros são criados pela função `add_points_secure`)

#### Tabela: `user_badges`

Registra os badges conquistados por cada usuário.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `user_id` | UUID | ❌ | - | ID do usuário |
| `badge_name` | TEXT | ❌ | - | Nome do badge |
| `badge_description` | TEXT | ✅ | - | Descrição do badge |
| `earned_at` | TIMESTAMPTZ | ✅ | NOW() | Data em que conquistou |

**Constraints:**
- `UNIQUE(user_id, badge_name)` - Cada badge só pode ser conquistado uma vez

**Índices:**
- `idx_user_badges_user` em `user_id`
- `idx_user_badges_name` em `badge_name`
- `idx_user_badges_unique` em `(user_id, badge_name)` (UNIQUE)

**Triggers:**
- `badge_notify_only_trigger`: Notifica quando conquista badge

#### Tabela: `badges`

Definição dos badges disponíveis.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `name` | TEXT | ❌ | - | Nome do badge (UNIQUE) |
| `description` | TEXT | ✅ | - | Descrição do badge |
| `category` | TEXT | ✅ | - | Categoria: 'iniciante', 'engajamento', 'social', 'streaks', 'comunidades' |
| `emoji` | TEXT | ✅ | - | Emoji que representa o badge |
| `points_bonus` | INTEGER | ✅ | 0 | Pontos bônus ao conquistar |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Constraints:**
- `UNIQUE(name)`

**Índices:**
- `idx_badges_name` em `name` (UNIQUE)
- `idx_badges_category` em `category`

#### Tabela: `levels`

Definição dos níveis de progressão.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `level` | INTEGER | ❌ | - | Número do nível (1-10, UNIQUE) |
| `name` | TEXT | ❌ | - | Nome do nível: 'Iniciante', 'Lenda', etc. |
| `points_required` | INTEGER | ❌ | - | Pontos necessários para atingir |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Constraints:**
- `UNIQUE(level)`

**Índices:**
- `idx_levels_level` em `level` (UNIQUE)
- `idx_levels_points` em `points_required`

#### Tabela: `user_streaks`

Armazena o streak atual e o mais longo de cada usuário.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `user_id` | UUID | ❌ | - | ID do usuário (UNIQUE) |
| `current_streak` | INTEGER | ✅ | 0 | Dias consecutivos atuais |
| `longest_streak` | INTEGER | ✅ | 0 | Maior streak já alcançado |
| `last_activity_date` | DATE | ✅ | - | Data da última atividade |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última atualização |

**Constraints:**
- `UNIQUE(user_id)`
- `CHECK (current_streak >= 0)`
- `CHECK (longest_streak >= 0)`

**Índices:**
- `idx_user_streaks_user` em `user_id` (UNIQUE)
- `idx_user_streaks_current` em `current_streak DESC`

**Triggers:**
- `streak_notify_only_trigger`: Notifica ao atingir marcos de streak

---

### 4.5. Grupo: Comunidades

#### Tabela: `communities`

Armazena informações das comunidades privadas.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `name` | TEXT | ❌ | - | Nome da comunidade |
| `slug` | TEXT | ❌ | - | URL amigável (UNIQUE) |
| `description` | TEXT | ✅ | - | Descrição da comunidade |
| `emoji` | TEXT | ✅ | '🏢' | Emoji que representa a comunidade |
| `logo_url` | TEXT | ✅ | - | URL do logo |
| `owner_id` | UUID | ❌ | - | ID do dono (FK para `profiles.id`) |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última atualização |
| `is_active` | BOOLEAN | ✅ | TRUE | Se a comunidade está ativa |
| `is_age_restricted` | BOOLEAN | ✅ | FALSE | Se a comunidade tem restrição de idade |
| `min_age_to_post` | INTEGER | ✅ | NULL | Idade mínima para postar (ex: 60) |
| `allow_multiple_feedbacks` | BOOLEAN | ✅ | FALSE | Se permite múltiplos feedbacks do mesmo usuário |

**Constraints:**
- `UNIQUE(slug)`

**Índices:**
- `idx_communities_owner` em `owner_id`
- `idx_communities_slug` em `slug` (UNIQUE)
- `idx_communities_active` em `is_active` WHERE `is_active = TRUE`

**Triggers:**
- Nenhum (comunidades são criadas pela função `create_community`)

#### Tabela: `community_members`

Armazena membros das comunidades.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `community_id` | UUID | ❌ | - | ID da comunidade |
| `user_id` | UUID | ❌ | - | ID do usuário |
| `role` | TEXT | ✅ | 'member' | Papel: 'owner' ou 'member' |
| `joined_at` | TIMESTAMPTZ | ✅ | NOW() | Data de entrada |
| `is_active` | BOOLEAN | ✅ | TRUE | Se o membro está ativo |

**Constraints:**
- `UNIQUE(community_id, user_id)`
- `CHECK (role IN ('owner', 'member'))`

**Índices:**
- `idx_community_members_community` em `community_id`
- `idx_community_members_user` em `user_id`
- `idx_community_members_active` em `(community_id, is_active)` WHERE `is_active = TRUE`

**Triggers:**
- Nenhum (membros são adicionados pela função `add_community_member`)

---

### 4.6. Grupo: Chat (Mensagens Diretas)

#### Tabela: `conversations`

Armazena conversas entre usuários.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `gen_random_uuid()` | ID único |
| `user1_id` | UUID | ❌ | - | ID do primeiro usuário |
| `user2_id` | UUID | ❌ | - | ID do segundo usuário |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |
| `updated_at` | TIMESTAMPTZ | ✅ | NOW() | Data da última mensagem |

**Constraints:**
- `UNIQUE(user1_id, user2_id)`
- `CHECK (user1_id < user2_id)` - Garante ordem consistente

**Índices:**
- `idx_conversations_users` em `(user1_id, user2_id)` (UNIQUE)
- `idx_conversations_user1` em `user1_id`
- `idx_conversations_user2` em `user2_id`

**Triggers:**
- `trigger_update_conversation_timestamp`: Atualiza `updated_at` ao receber mensagem

#### Tabela: `messages`

Armazena mensagens dentro de conversas.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `gen_random_uuid()` | ID único |
| `conversation_id` | UUID | ❌ | - | ID da conversa |
| `sender_id` | UUID | ❌ | - | ID do remetente |
| `content` | TEXT | ❌ | - | Conteúdo da mensagem |
| `is_read` | BOOLEAN | ✅ | FALSE | Se foi lida |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de envio |

**Constraints:**
- `CHECK (LENGTH(TRIM(content)) > 0)`

**Índices:**
- `idx_messages_conversation` em `(conversation_id, created_at DESC)`
- `idx_messages_sender` em `sender_id`
- `idx_messages_unread` em `(conversation_id, is_read)` WHERE `is_read = FALSE`

**Triggers:**
- Nenhum

---

### 4.7. Grupo: Correntes (Chains)

#### Tabela: `chains`

Armazena as correntes temáticas criadas pelos usuários.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `creator_id` | UUID | ❌ | - | ID do criador (FK para `profiles.id`) |
| `name` | TEXT | ❌ | - | Nome da corrente (3-50 caracteres) |
| `description` | TEXT | ❌ | - | Descrição/propósito (10-200 caracteres) |
| `highlight_type` | TEXT | ❌ | - | Tipo de destaque exigido para todos os posts da corrente |
| `status` | TEXT | ✅ | 'pending' | Status: 'pending', 'active', 'completed' |
| `first_post_id` | UUID | ✅ | - | ID do post que iniciou a corrente |
| `start_date` | TIMESTAMPTZ | ✅ | NOW() | Data de início |
| `end_date` | TIMESTAMPTZ | ✅ | - | Data de término (opcional) |
| `is_memorias_vivas` | BOOLEAN | ❌ | false | Indica se a corrente pertence ao feed Memórias Vivas (participação restrita a 60+) |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**Funções Relacionadas:**
- `create_chain()`: Cria uma nova corrente. Se `is_memorias_vivas = true`, valida que o criador tem 60+ anos via `can_post_in_memorias_vivas()`
- `get_chain_info()`: Retorna informações da corrente incluindo total de posts, participantes e flag `is_memorias_vivas`

#### Tabela: `chain_posts`

Relaciona posts às correntes.

| Campo | Tipo | Nullable | Default | Descrição |
|:---|:---|:---:|:---|:---|
| `id` | UUID | ❌ | `uuid_generate_v4()` | ID único |
| `chain_id` | UUID | ❌ | - | ID da corrente (FK para `chains.id`) |
| `post_id` | UUID | ❌ | - | ID do post (FK para `posts.id`) |
| `author_id` | UUID | ❌ | - | ID do autor do post |
| `parent_post_author_id` | UUID | ✅ | - | ID do autor do post anterior na corrente |
| `created_at` | TIMESTAMPTZ | ✅ | NOW() | Data de criação |

**RLS Policy Especial (Correntes MV):**
- A policy de INSERT em `chain_posts` verifica se a corrente é do Memórias Vivas (`is_memorias_vivas = true`). Se for, valida que o usuário tem 60+ anos via `can_post_in_memorias_vivas(auth.uid())`

---

### 4.8. Feed Memórias Vivas

O feed Memórias Vivas (📖) é um espaço dedicado a usuários com 60+ anos. Possui 6 tipos de post exclusivos:

| Tipo (sufixo `_mv`) | Emoji | Descrição |
|:---|:---|:---|
| `memoria_mv` | 💭 | Memória |
| `conselho_mv` | 💡 | Conselho |
| `epoca_ouro_mv` | ✨ | Época de Ouro |
| `historia_mv` | 📜 | História |
| `licao_vida_mv` | 📚 | Lição de Vida |
| `tradicao_mv` | 🎭 | Tradição |

**Função de Validação:** `can_post_in_memorias_vivas(p_user_id UUID)` calcula a idade do usuário a partir de `birth_date` e retorna `true` se >= 60 anos.

**Regras de Visibilidade:**
- Todos os usuários podem **ver** posts e correntes do Memórias Vivas
- Apenas usuários com 60+ anos podem **criar** posts e **participar** de correntes do Memórias Vivas
- O botão "Participar da Corrente" fica oculto para usuários com menos de 60 anos

---

### 4.9. Tour de Onboarding

O sistema de onboarding utiliza a biblioteca **Shepherd.js** para guiar novos usuários pela plataforma.

**Gatilho:** Aparece automaticamente apenas na primeira vez que o usuário acessa o site após completar o cadastro (`has_completed_onboarding = false`).

**Função RPC:** `set_onboarding_completed()` marca o tour como concluído para o usuário autenticado.

**Acesso Manual:** Botão "🎓 Ver Tour Guiado" no modal de configurações permite rever o tour a qualquer momento.

---

## 5. Funções SQL (166 funções)

O sistema possui 166 funções SQL que contêm toda a lógica de negócio. A lista completa está em `sql/functions/` (1 arquivo por função). Abaixo estão as funções mais críticas organizadas por categoria.

### 5.1. Funções de Pontos

#### `add_points_secure()`

**Propósito:** Função central para conceder pontos a um usuário.

**Parâmetros:**
- `p_user_id UUID`: ID do usuário
- `p_points INTEGER`: Quantidade de pontos (positivo ou negativo)
- `p_action_type TEXT`: Tipo de ação ('post_created', 'reaction_received', etc.)
- `p_reference_id UUID`: ID de referência (ex: post_id)
- `p_reference_type TEXT`: Tipo de referência ('post', 'comment', 'reaction')

**Lógica:**
1. Insere registro em `points_history`
2. Atualiza `total_points` em `user_points` (ou cria registro se não existir)
3. Calcula novo nível via `calculate_user_level()`
4. Atualiza `current_level` em `user_points`

**Segurança:** `SECURITY DEFINER` - Executa com privilégios elevados

#### `calculate_user_level()`

**Propósito:** Calcula o nível do usuário baseado em seus pontos totais.

**Parâmetros:**
- `user_points INTEGER`: Pontos totais do usuário

**Retorno:** `INTEGER` - Nível (1-10)

**Lógica:**
1. Busca na tabela `levels` o maior nível cujo `points_required` é <= `user_points`
2. Retorna o nível encontrado

### 5.2. Funções de Badges

#### `auto_check_badges_with_bonus_after_action()`

**Propósito:** Trigger function que verifica se uma ação desbloqueou novos badges.

**Retorno:** `TRIGGER`

**Lógica:**
1. Identifica o `user_id` da ação (NEW.user_id)
2. Verifica condições para cada badge:
   - **Primeiro Holofote:** Se é o primeiro post do usuário
   - **10 Destaques:** Se o usuário tem 10+ posts
   - **50 Destaques:** Se o usuário tem 50+ posts
   - **100 Destaques:** Se o usuário tem 100+ posts
   - **Engajador:** Se o usuário deu 100+ reações
   - **10 Seguidores:** Se o usuário tem 10+ seguidores
   - **Altruísta:** Se o índice de altruísmo > 2.0
   - Etc.
3. Para cada badge desbloqueado:
   - Insere em `user_badges` (ON CONFLICT DO NOTHING)
   - Concede pontos bônus via `add_points_secure()`
   - Cria notificação de badge

**Segurança:** `SECURITY DEFINER`

### 5.3. Funções de Streaks

#### `calculate_user_streak()`

**Propósito:** Calcula os dias consecutivos de atividade de um usuário.

**Parâmetros:**
- `p_user_id UUID`: ID do usuário

**Retorno:** `INTEGER` - Dias consecutivos

**Lógica:**
1. Coleta todas as atividades do usuário (posts, comentários, reações, feedbacks)
2. Agrupa por data (convertida para o timezone do usuário)
3. Ordena datas de forma decrescente
4. Começa de hoje e vai para trás, contando dias consecutivos
5. Para no primeiro dia sem atividade
6. Se hoje não tem atividade, streak = 0
7. Atualiza `user_streaks` com o resultado
8. Se o novo streak é maior que `longest_streak`, atualiza também
9. Verifica marcos de streak (7, 30, 182, 365 dias) e concede bônus

**Segurança:** `SECURITY DEFINER`

### 5.4. Funções de Comunidades

#### `create_community()`

**Propósito:** Cria uma nova comunidade.

**Parâmetros:**
- `p_name TEXT`: Nome da comunidade
- `p_slug TEXT`: URL amigável
- `p_description TEXT`: Descrição
- `p_emoji TEXT`: Emoji
- `p_owner_id UUID`: ID do dono

**Retorno:** `UUID` - ID da comunidade criada

**Lógica:**
1. Verifica se `auth.uid() = p_owner_id`
2. Verifica se o usuário tem `community_owner = TRUE` em `profiles`
3. Insere em `communities`
4. Adiciona owner como membro em `community_members` com `role = 'owner'`
5. Concede badge "Owner de Comunidade"
6. Retorna `community_id`

**Segurança:** `SECURITY DEFINER`

#### `add_community_member()`

**Propósito:** Adiciona um membro a uma comunidade.

**Parâmetros:**
- `p_community_id UUID`: ID da comunidade
- `p_user_id UUID`: ID do usuário a ser adicionado

**Retorno:** `BOOLEAN` - TRUE se sucesso

**Lógica:**
1. Verifica se `auth.uid()` é owner da comunidade
2. Insere em `community_members` com `role = 'member'`
3. Concede badge "Membro de Comunidade" ao novo membro
4. Retorna TRUE

**Segurança:** `SECURITY DEFINER`

#### `get_community_feed()`

**Propósito:** Retorna posts de uma comunidade.

**Parâmetros:**
- `p_community_id UUID`: ID da comunidade
- `p_limit INTEGER`: Limite de posts (default 20)
- `p_offset INTEGER`: Offset para paginação (default 0)

**Retorno:** `TABLE` - Posts com dados do autor

**Lógica:**
1. Verifica se `auth.uid()` é membro ativo da comunidade
2. Busca posts onde `community_id = p_community_id`
3. Faz JOIN com `profiles` para dados do autor
4. Ordena por `created_at DESC`
5. Aplica LIMIT e OFFSET
6. Retorna posts

**Segurança:** `SECURITY DEFINER`

### 5.5. Funções de Notificações

#### `check_notification_spam()`

**Propósito:** Previne criação de notificações duplicadas em curto período.

**Parâmetros:**
- `p_user_id UUID`: ID do usuário que recebe
- `p_from_user_id UUID`: ID do usuário que gera
- `p_type TEXT`: Tipo de notificação
- `p_reference_id TEXT`: ID de referência (opcional)

**Retorno:** `BOOLEAN` - TRUE se é spam (não deve criar)

**Lógica:**
1. Busca notificações idênticas criadas nas últimas 1 hora
2. Se encontrar, retorna TRUE (é spam)
3. Caso contrário, retorna FALSE (pode criar)

**Segurança:** `SECURITY DEFINER`

### 5.6. Funções de Triggers

#### `handle_post_insert_secure()`

**Propósito:** Chamada após criação de post para conceder pontos.

**Retorno:** `TRIGGER`

**Lógica:**
1. Se o post tem `mentioned_user_id` (holofote):
   - Concede +20 pontos ao autor via `add_points_secure()`
   - Concede +15 pontos à pessoa mencionada
2. Se o post NÃO tem `mentioned_user_id` (post normal):
   - Concede +10 pontos ao autor
3. Recalcula pontos totais de ambos os usuários
4. Retorna NEW

**Segurança:** `SECURITY DEFINER`

#### `handle_reaction_insert_secure()`

**Propósito:** Chamada após criação de reação para conceder pontos.

**Retorno:** `TRIGGER`

**Lógica:**
1. Busca `user_id` do autor do post
2. Concede +3 pontos a quem reagiu
3. Concede +2 pontos ao autor do post (se não for ele mesmo)
4. Atualiza totais de pontos
5. Retorna NEW

**Segurança:** `SECURITY DEFINER`

#### `handle_comment_insert_secure()`

**Propósito:** Chamada após criação de comentário para conceder pontos.

**Retorno:** `TRIGGER`

**Lógica:**
1. Busca `user_id` do autor do post
2. Concede +7 pontos a quem comentou
3. Concede +5 pontos ao autor do post (se não for ele mesmo)
4. Recalcula pontos totais
5. Retorna NEW

**Segurança:** `SECURITY DEFINER`

#### `handle_feedback_insert_secure()`

**Propósito:** Chamada após criação de feedback para conceder pontos.

**Retorno:** `TRIGGER`

**Lógica:**
1. Concede +10 pontos a quem deu o feedback (`mentioned_user_id`)
2. Concede +8 pontos a quem recebeu o feedback (`author_id`)
3. Recalcula pontos totais de ambos
4. Retorna NEW

**Segurança:** `SECURITY DEFINER`

---

## 6. Triggers (32 triggers)

Os triggers automatizam a execução da lógica de negócio em resposta a eventos no banco de dados.

### 6.1. Triggers de Pontos e Gamificação

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `post_insert_secure_trigger` | `posts` | AFTER INSERT | `handle_post_insert_secure()` | Concede pontos ao criar post |
| `reaction_insert_secure_trigger` | `reactions` | AFTER INSERT | `handle_reaction_insert_secure()` | Concede pontos ao reagir |
| `reaction_delete_secure_trigger` | `reactions` | AFTER DELETE | `handle_reaction_delete_secure()` | Remove pontos ao deletar reação |
| `comment_insert_secure_trigger` | `comments` | AFTER INSERT | `handle_comment_insert_secure()` | Concede pontos ao comentar |
| `comment_delete_secure_trigger` | `comments` | AFTER DELETE | `handle_comment_delete_secure()` | Remove pontos ao deletar comentário |
| `feedback_insert_secure_trigger` | `feedbacks` | AFTER INSERT | `handle_feedback_insert_secure()` | Concede pontos ao dar feedback |

### 6.2. Triggers de Badges

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `auto_badge_check_bonus_posts` | `posts` | AFTER INSERT | `auto_check_badges_with_bonus_after_action()` | Verifica badges após post |
| `auto_badge_check_bonus_comments` | `comments` | AFTER INSERT | `auto_check_badges_with_bonus_after_action()` | Verifica badges após comentário |
| `auto_badge_check_bonus_reactions` | `reactions` | AFTER INSERT | `auto_check_badges_with_bonus_after_action()` | Verifica badges após reação |
| `auto_badge_check_bonus_feedbacks` | `feedbacks` | AFTER INSERT | `auto_check_badges_with_bonus_after_action()` | Verifica badges após feedback |
| `auto_badge_check_bonus_user_points` | `user_points` | AFTER UPDATE | `auto_check_badges_with_bonus_after_action()` | Verifica badges após mudança de pontos |
| `badge_notify_only_trigger` | `user_badges` | AFTER INSERT | `handle_badge_notification_only()` | Notifica ao conquistar badge |

### 6.3. Triggers de Streaks

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `update_streak_after_post` | `posts` | AFTER INSERT | `update_user_streak_trigger()` | Atualiza streak após post |
| `update_streak_after_comment` | `comments` | AFTER INSERT | `update_user_streak_trigger()` | Atualiza streak após comentário |
| `update_streak_after_reaction` | `reactions` | AFTER INSERT | `update_user_streak_trigger()` | Atualiza streak após reação |
| `update_streak_after_feedback` | `feedbacks` | AFTER INSERT | `update_user_streak_trigger()` | Atualiza streak após feedback |
| `streak_notify_only_trigger` | `user_streaks` | AFTER UPDATE | `handle_streak_notification_only()` | Notifica ao atingir marco de streak |

### 6.4. Triggers de Notificações

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `holofote_notification_trigger` | `posts` | AFTER INSERT | `handle_holofote_notification()` | Notifica pessoa destacada |
| `reaction_notification_simple_trigger` | `reactions` | AFTER INSERT | `handle_reaction_notification_only()` | Notifica autor do post |
| `comment_notification_correto_trigger` | `comments` | AFTER INSERT | `handle_comment_notification_only()` | Notifica autor do post |
| `feedback_notification_correto_trigger` | `feedbacks` | AFTER INSERT | `handle_feedback_notification_correto()` | Notifica autor do post |
| `follow_notification_correto_trigger` | `follows` | AFTER INSERT | `handle_follow_notification_correto()` | Notifica quem foi seguido |
| `level_up_notification_trigger` | `user_points` | AFTER UPDATE | `notify_level_up_definitive()` | Notifica ao subir de nível |

### 6.5. Triggers de Comunidades

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `trigger_award_first_community_post_badge` | `posts` | AFTER INSERT | `award_first_community_post_badge_func()` | Badge de primeiro post em comunidade |

### 6.6. Triggers Auxiliares

| Trigger | Tabela | Evento | Função Chamada | Propósito |
|:---|:---|:---|:---|:---|
| `trigger_generate_username` | `profiles` | BEFORE INSERT/UPDATE | `generate_username_from_email()` | Gera username automaticamente |
| `trigger_update_conversation_timestamp` | `messages` | AFTER INSERT | `update_conversation_timestamp()` | Atualiza `updated_at` da conversa |
| `update_badges_updated_at` | `badges` | BEFORE UPDATE | `update_updated_at_column()` | Atualiza `updated_at` |
| `update_user_points_updated_at` | `user_points` | BEFORE UPDATE | `update_updated_at_column()` | Atualiza `updated_at` |

---

## 7. Arquitetura do Frontend

O frontend é uma Single-Page Application (SPA) contida em um único arquivo `index.html` com **~21.000+ linhas**.

### 7.1. Estrutura do `index.html`

```
index.html (~21.000+ linhas)
├── <head> (linhas 1-100)
│   ├── Meta tags (charset, viewport, description)
│   ├── Links para fontes (Google Fonts)
│   ├── Scripts externos (Supabase JS, Chart.js)
│   └── Scripts de comunidades (emoji_picker.js, community_feeds.js, community_management.js)
│
├── <style> (linhas 100-2000)
│   ├── Reset CSS
│   ├── Variáveis CSS (cores, gradientes)
│   ├── Layout principal (Flexbox, Grid)
│   ├── Componentes (cards, modais, botões)
│   ├── Animações (keyframes, transitions)
│   └── Responsividade (media queries)
│
├── <body> (linhas 2000-10000)
│   ├── Container principal (#app)
│   ├── Tela de login/cadastro
│   ├── Interface principal (após login)
│   │   ├── Header (logo, notificações, perfil)
│   │   ├── Sidebar (navegação)
│   │   ├── Feed (tabs dinâmicas)
│   │   ├── Aba Perfil
│   │   ├── Aba Impacto (métricas)
│   │   └── Aba Chat
│   └── Modais (30+ modais)
│       ├── Modal de criar post
│       ├── Modal de perfil de usuário
│       ├── Modal de post completo
│       ├── Modal de gerenciar comunidades
│       ├── Modal de emoji picker
│       └── Etc.
│
└── <script> (linhas 10000-15856)
    ├── Configuração do Supabase
    ├── Variáveis globais (currentUser, etc.)
    ├── Funções de autenticação
    ├── Funções de posts (criar, listar, deletar)
    ├── Funções de comentários e reações
    ├── Funções de perfil
    ├── Funções de notificações
    ├── Funções de métricas
    ├── Funções de chat
    ├── Classes (ProfileRouter, PostRouter)
    ├── Event listeners
    └── Inicialização (DOMContentLoaded)
```

### 7.2. JavaScript

O código JavaScript é **procedural** com algumas **classes** para funcionalidades mais complexas.

#### **Padrões de Código:**

- **Nomenclatura:**
  - Funções: `camelCase` (ex: `loadUserData`, `createPost`)
  - Classes: `PascalCase` (ex: `ProfileRouter`, `PostRouter`)
  - Constantes: `UPPER_SNAKE_CASE` (ex: `SUPABASE_URL`)

- **Organização:**
  - Seções delimitadas por comentários `// ===== SEÇÃO =====`
  - Funções agrupadas por funcionalidade
  - Event listeners concentrados no final
  - Inicialização via `DOMContentLoaded`

- **Tratamento de Erros:**
  - Try-catch em todas as operações assíncronas
  - Logs detalhados no console
  - Mensagens de erro amigáveis ao usuário

#### **Bibliotecas Externas:**

- **`@supabase/supabase-js`**: Cliente oficial do Supabase
  ```javascript
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  ```

- **`chart.js`**: Visualização de dados
  ```javascript
  new Chart(ctx, {
    type: 'line',
    data: { ... },
    options: { ... }
  });
  ```

#### **Scripts Modulares (Comunidades):**

- **`/js/emoji_picker.js`**: Seletor de emojis
  - Função: `initEmojiPicker()`
  - Função: `openEmojiPicker(callback)`
  - Função: `selectEmoji(emoji)`

- **`/js/community_feeds.js`**: Tabs dinâmicas de feeds
  - Função: `loadUserCommunities()`
  - Função: `setupFeedTabs()`
  - Função: `switchFeed(feedType, communityId)`
  - Função: `getActiveCommunityId()`

- **`/js/community_management.js`**: CRUD de comunidades
  - Função: `initCommunityManagement()`
  - Função: `openManageCommunityModal()`
  - Função: `createCommunity(formData)`
  - Função: `addMember(communityId, userId)`

### 7.3. Roteamento (History API)

O roteamento para páginas de perfil e posts é implementado manualmente com classes que manipulam a History API.

#### **Classe `ProfileRouter`:**

```javascript
class ProfileRouter {
  showFullProfile(userId) {
    // Oculta interface principal
    // Mostra container de perfil completo
    // Atualiza URL: ?profile=username
    // Carrega dados do perfil
  }
  
  closeFullProfile() {
    // Mostra interface principal
    // Oculta container de perfil completo
    // Remove ?profile= da URL
  }
  
  loadFullProfile(userId) {
    // Busca dados do perfil no Supabase
    // Renderiza perfil completo
  }
}
```

#### **Classe `PostRouter`:**

```javascript
class PostRouter {
  showFullPost(postId) {
    // Oculta interface principal
    // Mostra container de post completo
    // Atualiza URL: ?post=post_id
    // Carrega dados do post
  }
  
  closeFullPost() {
    // Mostra interface principal
    // Oculta container de post completo
    // Remove ?post= da URL
  }
  
  loadFullPost(postId) {
    // Busca dados do post no Supabase
    // Renderiza post completo
  }
}
```

### 7.4. CSS

O CSS está embutido no `index.html` e utiliza:

- **Flexbox e Grid** para layout
- **Gradientes** para visual moderno
- **`backdrop-filter`** para efeito de vidro fosco
- **Transições e Keyframes** para animações
- **Media Queries** para responsividade

**Exemplo de Gradiente:**
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

**Exemplo de Backdrop Filter:**
```css
backdrop-filter: blur(10px);
background: rgba(255, 255, 255, 0.1);
```

### 7.5. Hospedagem (Vercel)

O frontend é hospedado na Vercel via integração com GitHub.

**Arquivo `vercel.json`:**
```json
{
  "version": 2,
  "builds": [
    {
      "src": "index.html",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

**Fluxo de Deploy:**
1. Desenvolvedor faz `git push` para `main`
2. GitHub webhook notifica Vercel
3. Vercel faz build (copia arquivos estáticos)
4. Vercel distribui via CDN global
5. Site atualizado em ~30 segundos

---

## 8. Segurança e RLS

A segurança é garantida principalmente no nível do banco de dados através de Row Level Security (RLS).

### 8.1. Row Level Security (RLS)

**Todas as 21 tabelas possuem RLS ativado.** A lista completa de policies está em `sql/policies/` (83 policies no total).

#### **Princípios das Políticas:**

1. **Propriedade:** Usuários só podem editar/deletar seus próprios dados
   ```sql
   CREATE POLICY "Users can update own profile"
   ON profiles FOR UPDATE
   USING (auth.uid() = id);
   ```

2. **Privacidade:** Usuários só veem suas próprias notificações
   ```sql
   CREATE POLICY "Users can view own notifications"
   ON notifications FOR SELECT
   USING (auth.uid() = user_id);
   ```

3. **Acesso Público Controlado:** Posts globais são públicos para leitura
   ```sql
   CREATE POLICY "Posts are publicly readable"
   ON posts FOR SELECT
   USING (
     community_id IS NULL OR
     community_id IN (
       SELECT community_id FROM community_members 
       WHERE user_id = auth.uid() AND is_active = true
     )
   );
   ```

4. **Isolamento de Comunidades:** Apenas membros veem posts da comunidade
   ```sql
   CREATE POLICY "Members can view community posts"
   ON posts FOR SELECT
   USING (
     community_id IN (
       SELECT community_id FROM community_members 
       WHERE user_id = auth.uid() AND is_active = true
     )
   );
   ```

5. **Moderação:** Donos de comunidades podem editar/deletar posts
   ```sql
   CREATE POLICY "Owner can delete community posts"
   ON posts FOR DELETE
   USING (
     auth.uid() = user_id OR
     community_id IN (
       SELECT community_id FROM community_members 
       WHERE user_id = auth.uid() AND role = 'owner'
     )
   );
   ```

### 8.2. Funções com `SECURITY DEFINER`

Funções que executam operações sensíveis são definidas com `SECURITY DEFINER`.

**O que significa:**
- A função executa com os privilégios do seu criador (administrador do banco)
- Não com os privilégios do usuário que a chama
- Permite que a função acesse tabelas/campos que o usuário não pode
- **MAS** a função deve ter verificações de autorização explícitas

**Exemplo:**
```sql
CREATE OR REPLACE FUNCTION add_points_secure(...)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- Executa como admin
SET search_path = public
AS $$
BEGIN
  -- Verificação explícita de autorização
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  
  -- Lógica da função
  INSERT INTO points_history (...) VALUES (...);
  UPDATE user_points SET total_points = total_points + p_points ...;
END;
$$;
```

### 8.3. Proteções Adicionais

- **Anti-spam de Notificações:** `check_notification_spam()` previne duplicatas em 1 hora
- **Sanitização de Inputs:** `supabase-js` automaticamente sanitiza queries (proteção contra SQL Injection)
- **Autenticação Obrigatória:** Todas as operações de escrita requerem `auth.uid()` válido
- **Rate Limiting:** Supabase possui rate limiting nativo na API (configurável)

---

## 9. Fluxos de Dados Detalhados

### 9.1. Fluxo Completo: Criar Post de Reconhecimento

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USUÁRIO preenche formulário "Destacar Alguém"               │
│    - Pessoa a destacar: @joao                                   │
│    - Tipo: gratidão                                             │
│    - Conteúdo: "João sempre ajuda a equipe com soluções..."     │
│    - Foto: imagem.jpg (opcional)                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FRONTEND valida dados (createPost)                           │
│    - Verifica campos obrigatórios                               │
│    - Valida menção @joao contra tabela profiles                 │
│    - Verifica se usuário existe                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. FRONTEND faz upload de foto (se houver)                      │
│    - uploadPhoto() → Supabase Storage bucket 'post-images'      │
│    - Retorna URL pública: https://...supabase.co/.../imagem.jpg │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. FRONTEND insere post                                         │
│    supabase.from('posts').insert({                              │
│      user_id: 'uuid-autor',                                     │
│      celebrated_person_name: '@joao',                           │
│      content: 'João sempre ajuda...',                           │
│      type: 'gratitude',                                         │
│      photo_url: 'https://...imagem.jpg',                        │
│      community_id: null  // ou UUID se em comunidade           │
│    })                                                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. POSTGRESQL recebe INSERT                                     │
│    - RLS verifica se auth.uid() = user_id (autorizado)          │
│    - INSERT é executado                                         │
│    - Registro criado em posts                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. TRIGGER: post_insert_secure_trigger                          │
│    - Dispara AFTER INSERT ON posts                              │
│    - Chama handle_post_insert_secure()                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. FUNÇÃO: handle_post_insert_secure()                          │
│    a) Concede +10 pontos ao autor                               │
│       - add_points_secure(autor, 10, 'post_created', post_id)   │
│    b) Busca user_id de @joao em profiles                        │
│    c) Concede +5 pontos a @joao                                 │
│       - add_points_secure(joao, 5, 'mentioned_in_post', post_id)│
│    d) Registra em points_history (2 registros)                  │
│    e) Atualiza user_points (2 usuários)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. TRIGGER: auto_badge_check_bonus_posts                        │
│    - Dispara AFTER INSERT ON posts                              │
│    - Chama auto_check_badges_with_bonus_after_action()          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. FUNÇÃO: auto_check_badges_with_bonus_after_action()          │
│    a) Conta posts do autor: SELECT COUNT(*) FROM posts WHERE... │
│    b) Se é o primeiro post:                                     │
│       - Insere badge "Primeiro Holofote" em user_badges         │
│       - Concede +50 pontos bônus                                │
│    c) Se chegou a 10 posts:                                     │
│       - Insere badge "10 Destaques" em user_badges              │
│       - Concede +100 pontos bônus                               │
│    d) Etc. para outros badges                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 10. TRIGGER: holofote_notification_trigger                      │
│     - Dispara AFTER INSERT ON posts                             │
│     - Chama handle_holofote_notification()                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 11. FUNÇÃO: handle_holofote_notification()                      │
│     a) Verifica anti-spam: check_notification_spam(joao, autor) │
│     b) Se não é spam:                                           │
│        - Insere em notifications:                               │
│          user_id: joao                                          │
│          from_user_id: autor                                    │
│          type: 'holofote'                                       │
│          message: 'Maria te destacou em um post!'               │
│          reference_id: post_id                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 12. SUPABASE REALTIME envia eventos                             │
│     - Canal: public:posts → INSERT (novo post)                  │
│     - Canal: public:notifications → INSERT (nova notificação)   │
│     - Canal: public:user_points → UPDATE (pontos atualizados)   │
│     - Canal: public:user_badges → INSERT (novo badge, se houver)│
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 13. FRONTEND (do usuário @joao) recebe eventos via WebSocket    │
│     - Subscription callback é chamada                           │
│     - loadNotifications() busca nova notificação                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 14. INTERFACE atualiza automaticamente (SEM RELOAD)             │
│     - Contador de notificações: +1                              │
│     - Badge "novo" na aba de notificações                       │
│     - Som/vibração (se habilitado)                              │
│     - Toast notification: "Maria te destacou!"                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 15. FRONTEND (do autor) atualiza métricas                       │
│     - updateMetricsRealTime() é chamada                         │
│     - Atualiza contadores de posts criados                      │
│     - Atualiza pontos totais                                    │
│     - Atualiza nível (se mudou)                                 │
│     - Mostra toast: "Post criado! +10 pontos"                   │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2. Fluxo: Compartilhar Post via URL

```
1. Usuário clica em "Compartilhar" no post
   ↓
2. Frontend gera URL: holospot.com/?post=abc123
   ↓
3. Usuário copia URL e compartilha (WhatsApp, email, etc.)
   ↓
4. Destinatário clica no link
   ↓
5. Browser carrega holospot.com/?post=abc123
   ↓
6. Frontend detecta parâmetro ?post= na inicialização
   - Event listener: DOMContentLoaded
   - URLSearchParams detecta ?post=abc123
   ↓
7. Frontend chama PostRouter.showFullPost('abc123')
   - Oculta interface principal
   - Mostra container fullPostContainer
   - Atualiza URL via history.pushState
   ↓
8. Frontend carrega dados do post
   - supabase.from('posts').select('*, profiles(*)').eq('id', 'abc123')
   - Busca autor, mencionado, reações, comentários
   ↓
9. Frontend renderiza página completa do post
   - Header com logo e botão fechar
   - Conteúdo do post
   - Foto (se houver)
   - Autor e pessoa destacada
   - Reações e comentários
   - Meta tags Open Graph para preview
   ↓
10. Usuário pode interagir
    - Reagir ao post (se logado)
    - Comentar (se logado)
    - Fechar e voltar para feed
```

### 9.3. Fluxo: Criar Comunidade

```
1. @guilherme.dutra clica em "🏢 Gerenciar Comunidades"
   ↓
2. Frontend abre modal de gerenciamento
   - Carrega comunidades existentes
   ↓
3. Usuário clica em "Criar Nova Comunidade"
   ↓
4. Usuário preenche formulário:
   - Nome: "Equipe de Produto"
   - Slug: "equipe-produto"
   - Descrição: "Comunidade da equipe de produto..."
   - Clica em "Escolher Emoji" → abre emoji picker
   - Seleciona emoji: 🚀
   - URL do logo: (opcional)
   ↓
5. Usuário clica em "Criar Comunidade"
   ↓
6. Frontend chama função SQL:
   - supabase.rpc('create_community', {
       p_name: 'Equipe de Produto',
       p_slug: 'equipe-produto',
       p_description: 'Comunidade da equipe...',
       p_emoji: '🚀',
       p_owner_id: currentUser.id
     })
   ↓
7. BACKEND executa create_community():
   a) Verifica auth.uid() = p_owner_id ✓
   b) Verifica community_owner = true em profiles ✓
   c) Insere em communities:
      id: uuid-gerado
      name: 'Equipe de Produto'
      slug: 'equipe-produto'
      emoji: '🚀'
      owner_id: guilherme.dutra
   d) Insere em community_members:
      community_id: uuid-gerado
      user_id: guilherme.dutra
      role: 'owner'
   e) Concede badge "Owner de Comunidade"
   f) Retorna community_id
   ↓
8. Frontend recebe community_id
   ↓
9. Frontend atualiza lista de comunidades no modal
   ↓
10. Frontend adiciona nova tab no feed:
    - Chama loadUserCommunities()
    - Renderiza tab: "🚀 Equipe de Produto"
   ↓
11. Usuário vê nova tab no feed
```

---

## 10. Deploy e CI/CD

### 10.1. Controle de Versão (Git/GitHub)

**Repositório:** `https://github.com/holospotadm/holospot`

**Branches:**
- `main`: Branch de produção (protegida)

**Convenção de Commits:**
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `chore:` - Tarefas de manutenção
- `docs:` - Documentação
- `refactor:` - Refatoração de código

### 10.2. Migrations de Banco de Dados

**Localização:** `/sql/migrations/`

**Processo:**
1. Criar arquivo de migration: `YYYYMMDD_descricao.sql`
2. Escrever SQL completo (CREATE TABLE, ALTER TABLE, CREATE FUNCTION, etc.)
3. Testar localmente (se possível)
4. Abrir Supabase Dashboard → SQL Editor
5. Copiar conteúdo do arquivo
6. Colar no SQL Editor
7. Clicar em "Run"
8. Verificar sucesso
9. Fazer commit do arquivo no GitHub

**Exemplo de Migration:**
```sql
-- Migration: 20241029_communities_feature_v2.sql
-- Descrição: Adiciona funcionalidade de comunidades

-- 1. Adicionar campo community_owner em profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS community_owner BOOLEAN DEFAULT false;

-- 2. Criar tabela communities
CREATE TABLE IF NOT EXISTS communities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  ...
);

-- 3. Criar funções
CREATE OR REPLACE FUNCTION create_community(...)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  ...
END;
$$;

-- 4. Habilitar @guilherme.dutra
UPDATE profiles 
SET community_owner = true 
WHERE username = 'guilherme.dutra';
```

### 10.3. Deploy do Frontend

**Automático via Vercel:**

1. Desenvolvedor faz alterações no `index.html`
2. Desenvolvedor faz commit: `git commit -m "feat: Add new feature"`
3. Desenvolvedor faz push: `git push origin main`
4. GitHub webhook notifica Vercel
5. Vercel inicia build:
   - Clona repositório
   - Copia arquivos estáticos
   - Valida configuração (`vercel.json`)
6. Vercel distribui via CDN global (150+ localizações)
7. Site atualizado em ~30 segundos
8. Vercel envia notificação de sucesso

**Rollback:**
- Vercel mantém histórico de deploys
- Possível fazer rollback para qualquer deploy anterior via dashboard

### 10.4. Deploy do Backend

**Manual via Supabase Dashboard:**

1. Desenvolvedor cria migration SQL
2. Desenvolvedor testa migration (se possível)
3. Desenvolvedor abre Supabase Dashboard
4. Desenvolvedor executa migration no SQL Editor
5. Desenvolvedor verifica sucesso
6. Desenvolvedor faz commit da migration no GitHub

**Não há rollback automático para migrations.** Se uma migration causar problemas, é necessário criar uma nova migration que reverta as mudanças.

---

## 11. Debugging e Troubleshooting

### 11.1. Debugging do Frontend

**Ferramentas:**
- **Browser DevTools (F12)**
  - Console: Logs de JavaScript
  - Network: Requisições HTTP
  - Application: LocalStorage, Cookies

**Técnicas:**
- Adicionar `console.log()` em pontos críticos
- Usar `debugger;` para breakpoints
- Verificar requisições no Network tab
- Verificar erros no Console tab

**Exemplo:**
```javascript
async function createPost(formData) {
  console.log('createPost called with:', formData);
  
  try {
    const { data, error } = await supabase.from('posts').insert(...);
    
    if (error) {
      console.error('Error creating post:', error);
      throw error;
    }
    
    console.log('Post created successfully:', data);
  } catch (err) {
    console.error('Caught error:', err);
  }
}
```

### 11.2. Debugging do Backend

**Ferramentas:**
- **Supabase Dashboard → Logs**
  - PostgreSQL Logs
  - API Logs
  - Realtime Logs

**Técnicas:**
- Adicionar `RAISE NOTICE` em funções SQL
- Verificar logs do PostgreSQL
- Executar queries manualmente no SQL Editor

**Exemplo:**
```sql
CREATE OR REPLACE FUNCTION create_community(...)
RETURNS UUID
AS $$
DECLARE
  v_community_id UUID;
BEGIN
  RAISE NOTICE 'create_community called with name: %', p_name;
  
  -- Lógica da função
  INSERT INTO communities (...) VALUES (...) RETURNING id INTO v_community_id;
  
  RAISE NOTICE 'Community created with id: %', v_community_id;
  
  RETURN v_community_id;
END;
$$;
```

### 11.3. Problemas Comuns

#### **Problema: "relation does not exist"**

**Causa:** Tabela não foi criada ou migration não foi executada.

**Solução:**
1. Verificar se a migration foi executada no Supabase
2. Executar a migration manualmente
3. Verificar se o nome da tabela está correto

#### **Problema: "function does not exist"**

**Causa:** Função não foi criada ou migration não foi executada.

**Solução:**
1. Verificar se a migration foi executada no Supabase
2. Executar a migration manualmente
3. Verificar se a assinatura da função está correta

#### **Problema: "permission denied for table"**

**Causa:** RLS está bloqueando a operação.

**Solução:**
1. Verificar políticas de RLS na tabela
2. Verificar se o usuário está autenticado (`auth.uid()`)
3. Verificar se a política permite a operação

#### **Problema: "Trigger não está executando"**

**Causa:** Trigger não foi criado ou condição não foi atendida.

**Solução:**
1. Verificar se o trigger foi criado: `SELECT * FROM pg_trigger WHERE tgname = 'nome_do_trigger';`
2. Verificar se a condição `WHEN` está sendo atendida
3. Adicionar `RAISE NOTICE` na função do trigger para debug

#### **Problema: "Notificação não está sendo criada"**

**Causa:** Anti-spam está bloqueando ou função não está sendo chamada.

**Solução:**
1. Verificar se `check_notification_spam()` está retornando TRUE
2. Verificar se o trigger está executando
3. Verificar logs do PostgreSQL

---

## 12. Workflow de Desenvolvimento (OBRIGATÓRIO)

Esta seção define o workflow que DEVE ser seguido ao fazer alterações no HoloSpot. Este processo foi testado e comprovado, e garante consistência entre o código no GitHub e o ambiente de produção.

### 12.1. Princípios Fundamentais

1. **GitHub é a Fonte da Verdade:** Todos os arquivos no GitHub representam o estado atual do sistema
2. **Sempre Investigar Antes de Agir:** Use `grep`, leia o código, entenda o contexto
3. **Nunca Assumir:** Verifique se campos/funções/tabelas existem antes de usá-los
4. **Correções Completas:** Se um problema aparece em vários lugares, corrija TODOS
5. **Ordem Importa:** Siga o workflow na ordem correta (nunca inverta)

### 12.2. Workflow para Alterações no Frontend

#### **Arquivo Alvo:** `index.html`

**Passos:**

1. **Investigar o código atual:**
   ```bash
   cd /home/ubuntu/holospot
   grep -n "função_relacionada" index.html
   ```

2. **Fazer alterações no `index.html`:**
   - Editar diretamente o arquivo
   - Seguir padrões de código existentes
   - Adicionar comentários se necessário

3. **Testar localmente (se possível):**
   - Abrir `index.html` no navegador
   - Verificar console do navegador
   - Testar funcionalidade alterada

4. **Commitar no GitHub:**
   ```bash
   git add index.html
   git commit -m "feat: Descrição clara da alteração"
   git push origin main
   ```

5. **Deploy automático:**
   - Vercel detecta o push
   - Faz deploy automático
   - Frontend atualizado em ~2 minutos

**Exemplo de Commit:**
```bash
git commit -m "fix: Corrigir validação de email no formulário de cadastro"
```

### 12.3. Workflow para Alterações no Backend (SQL)

#### **Arquivos Alvo:**
- `sql/functions/ALL_FUNCTIONS.sql` - Para funções
- `sql/triggers/ALL_TRIGGERS.sql` - Para triggers
- `sql/schema/XX_nome_tabela.sql` - Para schemas de tabelas
- `sql/policies/XX_nome_tabela_policies.sql` - Para políticas RLS
- `sql/data/XX_nome_data.sql` - Para dados iniciais

**Passos:**

1. **Investigar o código atual:**
   ```bash
   cd /home/ubuntu/holospot
   
   # Buscar função
   grep -A 30 "CREATE OR REPLACE FUNCTION nome_funcao" sql/functions/ALL_FUNCTIONS.sql
   
   # Buscar trigger
   grep "nome_trigger" sql/triggers/ALL_TRIGGERS.sql
   
   # Buscar schema de tabela
   cat sql/schema/10_nome_tabela.sql
   ```

2. **Fazer alterações nos arquivos SQL:**
   - Editar o arquivo consolidado apropriado
   - **Funções:** Editar em `ALL_FUNCTIONS.sql`
   - **Triggers:** Editar em `ALL_TRIGGERS.sql`
   - **Schemas:** Editar arquivo específico em `sql/schema/`
   - Manter formatação e comentários

3. **Commitar no GitHub:**
   ```bash
   git add sql/functions/ALL_FUNCTIONS.sql  # ou outro arquivo
   git commit -m "fix: Corrigir cálculo de pontos em handle_post_insert_secure"
   git push origin main
   ```

4. **Executar script SQL no banco:**
   - Usar o utilitário Python `holospot_db.py` (exec_sql)
   - Executar a função/trigger alterado via API REST
   - Validar se a execução teve sucesso

5. **Commitar no GitHub:**
   - Após sucesso no banco, commitar os arquivos
   - Push para origin main
   - Monitorar deploy no Vercel

6. **Informar o usuário:**
   - Notificar que a alteração foi aplicada e está no ar
   - Solicitar validação de negócio (se necessário)

**Exemplo de Commit:**
```bash
git commit -m "fix: Corrigir pontuação de posts com menção (20 pts em vez de 10 pts)"
```

### 12.4. Workflow para Novas Tabelas

**Passos:**

1. **Criar arquivo de schema:**
   ```bash
   # Arquivo: sql/schema/XX_nome_tabela.sql
   # XX = número sequencial (próximo disponível)
   ```

2. **Definir schema completo:**
   ```sql
   CREATE TABLE public.nome_tabela (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
       campo1 TEXT NOT NULL,
       campo2 INTEGER DEFAULT 0,
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   
   -- Índices
   CREATE INDEX idx_nome_tabela_user_id ON public.nome_tabela(user_id);
   
   -- Comentários
   COMMENT ON TABLE public.nome_tabela IS 'Descrição da tabela';
   ```

3. **Criar arquivo de políticas RLS:**
   ```bash
   # Arquivo: sql/policies/XX_nome_tabela_policies.sql
   ```

4. **Definir políticas RLS:**
   ```sql
   ALTER TABLE public.nome_tabela ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view own records"
   ON public.nome_tabela FOR SELECT
   USING (auth.uid() = user_id);
   
   CREATE POLICY "Users can insert own records"
   ON public.nome_tabela FOR INSERT
   WITH CHECK (auth.uid() = user_id);
   ```

5. **Commitar ambos os arquivos:**
   ```bash
   git add sql/schema/XX_nome_tabela.sql sql/policies/XX_nome_tabela_policies.sql
   git commit -m "feat: Add nome_tabela table with RLS policies"
   git push origin main
   ```

6. **Enviar script SQL completo para o usuário:**
   - Incluir CREATE TABLE
   - Incluir índices
   - Incluir políticas RLS
   - Incluir comentários
   - Enviar via mensagem formatado e pronto para execução

### 12.5. Workflow para Migrations

**Quando usar:** Alterações em schemas existentes (adicionar coluna, modificar tipo, etc.)

**Passos:**

1. **Criar arquivo de migration:**
   ```bash
   # Arquivo: sql/migrations/YYYYMMDD_descricao.sql
   # Exemplo: sql/migrations/20251030_add_community_owner_to_profiles.sql
   ```

2. **Escrever migration:**
   ```sql
   -- Migration: Add community_owner field to profiles
   -- Date: 2025-10-30
   
   ALTER TABLE public.profiles 
   ADD COLUMN IF NOT EXISTS community_owner BOOLEAN DEFAULT FALSE;
   
   COMMENT ON COLUMN public.profiles.community_owner IS 
   'Indica se o usuário pode criar comunidades';
   ```

3. **Atualizar arquivo de schema:**
   - Editar `sql/schema/10_profiles.sql`
   - Adicionar novo campo no CREATE TABLE
   - Manter consistência

4. **Commitar ambos:**
   ```bash
   git add sql/migrations/20251030_add_community_owner_to_profiles.sql
   git add sql/schema/10_profiles.sql
   git commit -m "feat: Add community_owner field to profiles table"
   git push origin main
   ```

5. **Enviar script de migration para o usuário:**
   - Apenas o conteúdo do arquivo de migration
   - Formatado e pronto para execução
   - Enviar via mensagem
   - Usuário executa no Supabase SQL Editor

### 12.6. Ordem Correta do Workflow (NUNCA INVERTER)

```
1. 🔍 Investigar problema completamente
2. 📝 Modificar arquivos no GitHub
3. 💾 git add .
4. 💾 git commit -m "tipo: Descrição"
5. 💾 git push origin main
6. 📬 Enviar script SQL pronto para o usuário (se backend)
7. ✅ Aguardar confirmação de execução
8. 📝 Documentar se necessário
```

**NUNCA:**
- ❌ Executar SQL antes de commitar no GitHub
- ❌ Modificar apenas o banco sem atualizar GitHub
- ❌ Assumir que algo existe sem verificar
- ❌ Corrigir apenas uma ocorrência de problema sistêmico
- ❌ Pular etapas do workflow

### 12.7. Conventional Commits

Use prefixos padronizados nos commits:

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Alterações em documentação
- `refactor:` - Refatoração de código
- `perf:` - Melhoria de performance
- `test:` - Adição de testes
- `chore:` - Tarefas de manutenção

**Exemplos:**
```bash
feat: Add community creation functionality
fix: Correct points calculation in post trigger
docs: Update README with new gamification rules
refactor: Simplify badge checking logic
perf: Add index to posts.community_id
```

### 12.8. Checklist Antes de Commitar

- [ ] Investiguei o código atual completamente
- [ ] Entendi o problema e a solução
- [ ] Verifiquei TODAS as ocorrências do problema
- [ ] Corrigi TODAS as ocorrências (não apenas uma)
- [ ] Testei localmente (se possível)
- [ ] Escrevi mensagem de commit clara
- [ ] Preparei script SQL (se backend)
- [ ] Documentei alterações complexas

---

## 13. Considerações Finais

Este documento técnico fornece uma visão completa da arquitetura, tecnologias e implementação do HoloSpot. Para desenvolvedores que precisam trabalhar na plataforma:

1. **Leia este documento completamente** antes de fazer alterações
2. **Siga a metodologia documentada** no README.md principal
3. **Sempre investigue antes de agir** (grep no código, verificar schema, etc.)
4. **Teste localmente quando possível** antes de fazer deploy
5. **Documente suas alterações** em commits e migrations
6. **Respeite os padrões de código** estabelecidos

Para dúvidas ou problemas não cobertos neste documento, consulte:
- README.md principal
- Documentação do Supabase: https://supabase.com/docs
- Documentação do PostgreSQL: https://www.postgresql.org/docs/

---

**Autor:** Manus AI  
**Última Atualização:** 29 de dezembro de 2025  
**Versão do Documento:** 3.0
