# HoloSpot - README Funcional

**Autor:** Manus AI  
**Data:** 30 de outubro de 2025  
**Versão Analisada:** v6.1-enhanced (Commit 2b0dfb3)

---

## 1. Visão Geral e Conceito Principal

O HoloSpot é a **primeira rede social de bem-estar social**, projetada para combater os efeitos negativos das redes sociais tradicionais. A plataforma é construída sobre um conceito central: **colocar os holofotes nos outros**.

Em vez de autopromoção, os usuários são incentivados a criar posts que reconhecem e celebram as qualidades e conquistas de outras pessoas. Cada interação é projetada para gerar **gratidão, reconhecimento e conexões genuínas**, promovendo um ambiente online positivo e construtivo.

O sistema é sustentado por uma robusta mecânica de **gamificação**, que recompensa os usuários por seu engajamento positivo e por contribuírem para o bem-estar da comunidade.

## 2. Funcionalidades Principais

### 2.1. Feed de Atividades

O feed é a tela principal da aplicação e é dividido em abas dinâmicas:

- **Para Você:** Um feed algorítmico que mostra os posts mais relevantes de toda a rede.
- **Seguindo:** Um feed cronológico que exibe apenas os posts das pessoas que o usuário segue.
- **Feeds de Comunidades:** Para cada comunidade que o usuário participa, uma nova aba com o emoji e nome da comunidade é adicionada, exibindo um feed privado apenas com os posts daquela comunidade.

### 2.2. Criação de Posts ("Holofotes")

A funcionalidade central da plataforma. Ao criar um post, o usuário não fala sobre si mesmo, mas **destaca outra pessoa**.

- **Menção Obrigatória:** Todo post deve mencionar outro usuário da plataforma (`@username`).
- **Tipos de Reconhecimento:** O usuário pode categorizar o reconhecimento (ex: Gratidão, Conquista, Inspiração).
- **Conteúdo:** O post consiste em um texto descrevendo o reconhecimento.
- **Foto (Opcional):** O usuário pode anexar uma foto ao post.
- **Publicação em Comunidades:** Ao criar um post, se o usuário estiver visualizando o feed de uma comunidade, o post será publicado exclusivamente naquele feed privado.

### 2.3. Perfis de Usuário

Cada usuário possui uma página de perfil que exibe:

- Foto, nome e `@username`.
- Biografia.
- Estatísticas de gamificação (pontos, nível).
- Badges conquistados.
- Posts que o usuário criou e recebeu.
- Gráficos de evolução e métricas de impacto.

### 2.4. Sistema de Seguidores

Os usuários podem seguir uns aos outros. Seguir um usuário faz com que seus posts apareçam no feed "Seguindo".

### 2.5. Notificações em Tempo Real

O sistema de notificações informa os usuários sobre todas as interações relevantes, em tempo real e sem a necessidade de recarregar a página.

**Tipos de Notificação:**
- Quando alguém te destaca em um post.
- Quando alguém reage ao seu post.
- Quando alguém comenta no seu post.
- Quando alguém começa a te seguir.
- Quando você desbloqueia um novo badge.
- Quando você sobe de nível.
- Quando você atinge um marco de streak.

### 2.6. Páginas Únicas (Posts e Perfis)

Para facilitar o compartilhamento fora da plataforma, tanto posts quanto perfis possuem URLs únicas e compartilháveis:

- **URL de Post:** `holospot.com/?post=<post_id>`
- **URL de Perfil:** `holospot.com/?profile=<username>`

Acessar uma dessas URLs carrega diretamente uma visualização focada do post ou do perfil, permitindo que usuários externos vejam o conteúdo antes de entrar na aplicação principal.

### 2.7. Comunidades

As Comunidades são espaços privados dentro do HoloSpot, projetados para grupos específicos (empresas, equipes, famílias, etc.) se conectarem de forma mais focada.

**Características Funcionais:**

- **Criação Controlada:** A criação de comunidades é uma funcionalidade controlada, não aberta a todos os usuários. Atualmente, apenas o administrador (`@guilherme.dutra`) pode criar novas comunidades.
- **Feeds Privados:** Cada comunidade possui seu próprio feed, visível apenas para seus membros. Os posts criados dentro de uma comunidade não aparecem nos feeds globais ("Para Você" ou "Seguindo").
- **Tabs Dinâmicas:** A interface do feed principal é atualizada dinamicamente, adicionando uma nova aba para cada comunidade da qual o usuário faz parte.
- **Personalização:** Cada comunidade pode ter um nome, descrição, logo e um **emoji personalizado** que a representa visualmente nas abas do feed.
- **Gerenciamento de Membros:** O dono da comunidade pode adicionar ou remover membros.
- **Moderação:** O dono da comunidade tem privilégios de moderação, podendo editar ou deletar qualquer post feito dentro de sua comunidade para manter o ambiente seguro e alinhado aos seus objetivos.

## 3. Gamificação

A gamificação é o motor que incentiva o engajamento positivo na plataforma. Todas as ações de reconhecimento são recompensadas através de um sistema de pontos, badges, níveis e streaks.

### 3.1. Sistema de Pontos

Os usuários ganham pontos por interações que agregam valor à comunidade. A pontuação é projetada para valorizar mais a criação de conteúdo do que o consumo.

| Ação | Pontos para o Autor | Pontos para o Mencionado |
|:---|:---:|:---:|
| Criar um post de reconhecimento | +10 | +5 |
| Dar um feedback em um post | +3 | - |
| Receber um comentário no seu post | +2 | - |
| Receber uma reação no seu post | +1 | - |
| Desbloquear um badge | Bônus variável | - |
| Atingir um marco de streak | Bônus variável | - |

### 3.2. Badges (Conquistas)

Existem mais de 20 badges que os usuários podem colecionar, divididos em categorias que marcam a jornada do usuário na plataforma.

- **Iniciante:** Recompensa as primeiras ações (ex: "Primeiro Holofote", "Primeira Reação").
- **Engajamento:** Reconhece a consistência em criar conteúdo e interagir (ex: "10 Destaques", "Engajador").
- **Social:** Premia o crescimento da rede de conexões do usuário (ex: "10 Seguidores", "Influenciador").
- **Streaks:** Celebra a frequência e o hábito de engajamento diário (ex: "Semana Ativa", "Mês Ativo").
- **Comunidades:** Badges específicos por criar, entrar ou postar pela primeira vez em uma comunidade.

### 3.3. Níveis

À medida que os usuários acumulam pontos, eles progridem através de 10 níveis, que vão de "Iniciante" a "Lenda". Cada nível representa um novo patamar de contribuição para a comunidade HoloSpot.

### 3.4. Streaks de Atividade

O sistema de streaks incentiva o engajamento diário. Um "streak" é contado para cada dia consecutivo que o usuário realiza pelo menos uma atividade na plataforma (criar post, comentar, reagir ou dar feedback).

- **Visualização:** O usuário pode acompanhar seu progresso para os próximos marcos de streak (7, 30, 182 e 365 dias).
- **Bônus:** Atingir esses marcos concede uma quantidade significativa de pontos bônus e desbloqueia badges de streak.
- **Cálculo Preciso:** O sistema leva em conta o fuso horário de cada usuário para determinar corretamente a contagem de dias consecutivos.
