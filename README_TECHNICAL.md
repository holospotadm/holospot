# HoloSpot - README Técnico

**Autor:** Manus AI  
**Data:** 30 de outubro de 2025  
**Versão Analisada:** v6.1-enhanced (Commit 2b0dfb3)

---

## 1. Visão Geral da Arquitetura

O HoloSpot é construído sobre uma arquitetura **Jamstack** moderna, combinando um frontend estático com um backend dinâmico "serverless". A lógica de negócio é fortemente centralizada no banco de dados, seguindo o padrão **"Lógica no Banco"**.

### 1.1. Componentes Principais

| Componente | Tecnologia | Provedor | Responsabilidade |
|:---|:---|:---|:---|
| **Frontend** | HTML, CSS, JavaScript | Vercel | Interface do usuário (UI), renderização de dados |
| **Backend (BaaS)** | PostgreSQL, REST API, Realtime | Supabase | Banco de dados, autenticação, armazenamento, APIs |
| **Controle de Versão** | Git | GitHub | Repositório de código-fonte |

### 1.2. Fluxo de Dados

1.  O usuário interage com o `index.html` hospedado na Vercel.
2.  O JavaScript no frontend chama a API REST do Supabase para operações CRUD (Criar, Ler, Atualizar, Deletar).
3.  O banco de dados PostgreSQL, gerenciado pelo Supabase, recebe a requisição.
4.  **Triggers** no banco de dados interceptam a operação e chamam **funções PostgreSQL (plpgsql)**.
5.  As funções executam a lógica de negócio (ex: conceder pontos, criar notificações, verificar badges).
6.  As alterações no banco de dados são propagadas em tempo real para todos os clientes conectados via **Supabase Realtime (WebSockets)**.
7.  O frontend recebe o evento em tempo real e atualiza a UI dinamicamente, sem a necessidade de reload.

### 1.3. Padrão "Lógica no Banco"

Ao contrário de arquiteturas tradicionais onde a lógica de negócio reside em um servidor de aplicação (ex: Node.js, Python), o HoloSpot implementa essa lógica diretamente no PostgreSQL. 

- **Vantagens:** Consistência de dados garantida, segurança centralizada (via RLS e `SECURITY DEFINER`), e frontend agnóstico (qualquer cliente pode se conectar, pois a lógica é aplicada no banco).
- **Desvantagens:** Menor flexibilidade para mudanças rápidas, debugging pode ser mais complexo, e requer conhecimento especializado em SQL e plpgsql.


## 2. Arquitetura do Backend (Supabase + PostgreSQL)

O backend é 100% contido no Supabase, utilizando PostgreSQL como banco de dados e sua suíte de ferramentas para autenticação, armazenamento e APIs.

### 2.1. Banco de Dados (PostgreSQL)

#### **Schema do Banco de Dados**

O banco de dados é composto por **18 tabelas** principais, organizadas para suportar as funcionalidades da rede social.

| Tabela | Descrição |
|:---|:---|
| `profiles` | Armazena dados dos usuários (nome, username, avatar). Tabela central. |
| `posts` | Contém todos os posts de reconhecimento ("holofotes"). |
| `comments` | Armazena os comentários feitos nos posts. |
| `reactions` | Registra as reações (likes) dadas aos posts. |
| `follows` | Relação de quem segue quem. |
| `notifications` | Armazena todas as notificações geradas para os usuários. |
| `communities` | Tabela para as comunidades privadas. |
| `community_members` | Tabela de associação entre usuários e comunidades. |
| `badges` | Definição dos 20+ badges disponíveis. |
| `levels` | Definição dos 10 níveis de progressão. |
| `user_badges` | Registra os badges conquistados por cada usuário. |
| `user_points` | Armazena a pontuação total e o nível atual de cada usuário. |
| `points_history` | Log detalhado de todas as transações de pontos. |
| `user_streaks` | Armazena o streak atual e o mais longo de cada usuário. |
| `feedbacks` | Armazena os feedbacks dados nos posts. |
| `conversations` | Tabela para o sistema de chat. |
| `messages` | Armazena as mensagens do chat. |
| `notifications_updated` | Tabela auxiliar para otimização de notificações. |

#### **Funções SQL (plpgsql)**

O sistema possui **126 funções SQL** que contêm a lógica de negócio principal. Elas são chamadas por triggers ou diretamente pelo frontend via RPC (Remote Procedure Call).

**Exemplos de Funções Críticas:**
- `handle_post_insert_secure()`: Chamada após a criação de um post para conceder pontos ao autor e ao mencionado.
- `auto_check_badges_with_bonus_after_action()`: Verifica se uma nova ação (post, comentário, etc.) desbloqueou algum badge.
- `calculate_user_streak()`: Calcula os dias consecutivos de atividade de um usuário.
- `create_community()`: Cria uma nova comunidade e define o criador como owner.
- `add_community_member()`: Adiciona um membro a uma comunidade e concede o badge correspondente.
- `get_community_feed()`: Retorna o feed de posts de uma comunidade privada, verificando se o solicitante é membro.

#### **Triggers**

Existem **31 triggers** no banco de dados que automatizam a execução da lógica de negócio em resposta a eventos (INSERT, UPDATE, DELETE).

**Exemplos de Triggers:**
- `post_insert_secure_trigger`: Dispara após um `INSERT` na tabela `posts` para chamar `handle_post_insert_secure()`.
- `reaction_insert_secure_trigger`: Dispara após um `INSERT` na tabela `reactions` para conceder pontos.
- `trigger_award_first_community_post_badge`: Dispara após um `INSERT` na tabela `posts` com `community_id` para verificar o badge de primeiro post.
- `update_streak_after_post`: Dispara após a criação de um post para atualizar o streak do usuário.

### 2.2. API (Supabase Auto-generated)

O Supabase gera automaticamente uma API RESTful para todas as tabelas do banco de dados, respeitando as políticas de RLS. O frontend utiliza a biblioteca `supabase-js` para interagir com esta API.

**Operações Comuns:**
- `supabase.from('posts').select('*')`: Busca posts.
- `supabase.from('comments').insert({ ... })`: Insere um novo comentário.
- `supabase.rpc('create_community', { ... })`: Chama uma função SQL diretamente.

### 2.3. Realtime (WebSockets)

O Supabase Realtime permite que o frontend se inscreva a mudanças no banco de dados (INSERTs, UPDATEs, DELETEs) em tempo real. O HoloSpot usa isso extensivamente para criar uma experiência de usuário dinâmica.

**Exemplo de Inscrição:**
```javascript
supabase
  .channel('public:posts')
  .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'posts' }, payload => {
    // Adiciona o novo post ao feed em tempo real
    console.log('Novo post recebido!', payload.new);
  })
  .subscribe();
```

### 2.4. Autenticação (Supabase Auth)

O sistema utiliza o Supabase Auth para gerenciamento de usuários (cadastro, login, recuperação de senha). A tabela `auth.users` do Supabase é a fonte da verdade para autenticação, e a tabela `public.profiles` armazena os dados públicos do perfil, sendo sincronizada com a tabela de autenticação.

### 2.5. Armazenamento (Supabase Storage)

As imagens de perfil e fotos dos posts são armazenadas no Supabase Storage. O frontend faz o upload diretamente para o Storage e armazena apenas a URL pública da imagem no banco de dados (`avatar_url` em `profiles`, `photo_url` em `posts`).

## 3. Arquitetura do Frontend (SPA)

O frontend é uma **Single-Page Application (SPA)** contida em um único arquivo `index.html` com **15.856 linhas**, que inclui HTML, CSS e JavaScript.

### 3.1. Estrutura do `index.html`

- **`<head>`**: Contém metatags, links para fontes, e os scripts principais.
- **`<body>`**: Contém a estrutura HTML de toda a aplicação, incluindo todos os modais e contêineres de conteúdo que são exibidos ou ocultados dinamicamente via JavaScript.
- **`<style>`**: O CSS está embutido no `index.html`.
- **`<script>`**: O JavaScript principal está embutido no `index.html`, com scripts adicionais para a funcionalidade de comunidades sendo carregados de arquivos externos.

### 3.2. JavaScript

O código JavaScript é procedural, com algumas classes para funcionalidades mais complexas. Não utiliza frameworks modernos como React, Vue ou Angular.

**Bibliotecas Externas:**
- **`@supabase/supabase-js`**: Cliente oficial do Supabase para interagir com o backend.
- **`chart.js`**: Utilizada para renderizar os gráficos no dashboard de métricas.

**Scripts Modulares (Funcionalidade de Comunidades):**
- `/js/emoji_picker.js`: Implementa o seletor de emojis para as comunidades.
- `/js/community_feeds.js`: Gerencia as tabs dinâmicas dos feeds (global e de comunidades).
- `/js/community_management.js`: Gerencia a criação, edição e moderação das comunidades.

**Padrões de Código:**
- **Inicialização:** A aplicação é inicializada no evento `DOMContentLoaded`.
- **Gerenciamento de Estado:** O estado do usuário (`currentUser`) e outras variáveis globais são mantidos em variáveis no escopo global.
- **Manipulação do DOM:** Utiliza `document.getElementById` e `document.querySelector` para manipular elementos da página.
- **Roteamento:** O roteamento para páginas de perfil (`/?profile=username`) e posts (`/?post=post_id`) é implementado manualmente com classes (`ProfileRouter`, `PostRouter`) que manipulam a History API (`history.pushState`).

### 3.3. CSS

O CSS está embutido no `index.html` e utiliza Flexbox e Grid para layout. As animações são feitas com transições e keyframes CSS. O design utiliza gradientes e o efeito `backdrop-filter` para criar uma aparência moderna.

### 3.4. Hospedagem (Vercel)

O frontend estático é hospedado na Vercel. O arquivo `vercel.json` configura o projeto para ser servido como um site estático, com o `index.html` como ponto de entrada.

## 4. Segurança e Privacidade

A segurança é um pilar central da arquitetura do HoloSpot, garantida principalmente no nível do banco de dados.

### 4.1. Row Level Security (RLS)

**Todas as 18 tabelas do banco de dados possuem RLS ativado.** Isso significa que nenhuma operação (SELECT, INSERT, UPDATE, DELETE) é permitida a menos que uma política explícita a autorize.

**Princípios das Políticas de RLS:**
- **Propriedade:** Usuários só podem editar ou deletar seus próprios dados (ex: `auth.uid() = user_id`).
- **Privacidade:** Usuários só podem ver suas próprias notificações e mensagens.
- **Acesso Público Controlado:** Posts globais são públicos para leitura (`SELECT`), mas a escrita (`INSERT`) é restrita ao autor.
- **Isolamento de Comunidades:** As políticas em `posts` e `community_members` garantem que apenas membros de uma comunidade possam ver seu conteúdo e seus membros.
- **Moderação:** Políticas especiais permitem que donos de comunidades (`role = 'owner'`) editem ou deletem posts de outros membros dentro de sua comunidade.

### 4.2. Funções com `SECURITY DEFINER`

Funções que executam operações sensíveis (como `add_points_secure` ou `create_community`) são definidas com `SECURITY DEFINER`. Isso faz com que a função execute com os privilégios do seu criador (o administrador do banco), não do usuário que a chama. Isso permite que a função acesse tabelas e campos que o usuário final não pode, mas sempre com verificações de autorização explícitas dentro da função (ex: `IF NOT EXISTS (SELECT 1 FROM community_members WHERE ...)`).

### 4.3. Proteções Adicionais

- **Anti-spam de Notificações:** A função `check_notification_spam` previne a criação de notificações duplicadas para a mesma ação em um curto período de tempo.
- **Sanitização de Inputs:** A biblioteca `supabase-js` automaticamente sanitiza os inputs para prevenir SQL Injection.
- **Autenticação Obrigatória:** Todas as operações de escrita requerem um `auth.uid()` válido, garantindo que apenas usuários autenticados possam modificar dados.

## 5. Sistema de Gamificação (Implementação Técnica)

A gamificação é totalmente automatizada no backend através de triggers e funções SQL.

### 5.1. Pontos

- A tabela `points_history` registra cada transação de pontos.
- A tabela `user_points` armazena o total de pontos e o nível atual de cada usuário (servindo como um cache para evitar recálculos constantes).
- A função `add_points_secure` é o ponto central para conceder pontos, sendo chamada por diversos triggers.

### 5.2. Badges

- A tabela `badges` contém as definições dos badges.
- A tabela `user_badges` armazena os badges conquistados.
- A função `auto_check_badges_with_bonus_after_action` é chamada por triggers após ações relevantes (posts, comentários, etc.) para verificar se novos badges foram desbloqueados.

### 5.3. Níveis

- A tabela `levels` define a quantidade de pontos necessária para cada nível.
- A função `calculate_user_level` é chamada para determinar o nível do usuário com base em seus pontos totais, e o resultado é armazenado em `user_points`.

### 5.4. Streaks

- A tabela `user_streaks` armazena o streak atual e o mais longo.
- A função `calculate_user_streak` é chamada por triggers após qualquer atividade do usuário (post, comentário, reação, feedback) para recalcular os dias consecutivos de atividade. A função leva em conta o `timezone` do usuário (armazenado em `profiles`) para cálculos precisos.

## 6. Metodologia de Desenvolvimento e Deploy

### 6.1. Controle de Versão (Git/GitHub)

- O código-fonte é versionado no GitHub.
- A branch `main` representa o estado de produção.
- Commits seguem o padrão **Conventional Commits** (ex: `feat:`, `fix:`, `chore:`).

### 6.2. Migrations de Banco de Dados

- Alterações no schema do banco de dados (tabelas, funções, triggers) são escritas em arquivos `.sql` na pasta `/sql/migrations/`.
- As migrations são projetadas para serem executadas manualmente no **SQL Editor** do Supabase.
- A convenção é criar um arquivo de migração completo por feature (ex: `20241029_communities_feature_v2.sql`) que contém todas as alterações necessárias.

### 6.3. Deploy

- **Backend:** O deploy do backend consiste em executar os scripts de migração SQL no Supabase.
- **Frontend:** O deploy do frontend é automático. Um `git push` para a branch `main` no GitHub dispara um webhook que aciona um novo build e deploy na Vercel.
