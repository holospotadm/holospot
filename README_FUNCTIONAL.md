# HoloSpot - Documentação Funcional Completa

**Autor:** Manus AI  
**Data:** 30 de outubro de 2025  
**Versão:** v6.1-enhanced (Commit 2b0dfb3)  
**Propósito:** Documentação funcional completa para entender TODAS as funcionalidades da rede social HoloSpot

---

## Índice

1. [O que é o HoloSpot](#1-o-que-é-o-holospot)
2. [Conceito Central e Filosofia](#2-conceito-central-e-filosofia)
3. [Jornada do Usuário Completa](#3-jornada-do-usuário-completa)
4. [Funcionalidades Detalhadas](#4-funcionalidades-detalhadas)
5. [Sistema de Gamificação Completo](#5-sistema-de-gamificação-completo)
6. [Comunidades Privadas](#6-comunidades-privadas)
7. [Notificações e Tempo Real](#7-notificações-e-tempo-real)
8. [Métricas e Impacto](#8-métricas-e-impacto)
9. [Chat e Mensagens Diretas](#9-chat-e-mensagens-diretas)
10. [Compartilhamento e URLs](#10-compartilhamento-e-urls)

---

## 1. O que é o HoloSpot

O HoloSpot é a **primeira rede social de bem-estar social** do mundo. Diferente de redes tradicionais que incentivam autopromoção e comparação, o HoloSpot foi projetado para criar um ambiente online positivo onde cada ação é voltada para **reconhecer e celebrar outras pessoas**.

### 1.1. Missão

> "Transformar vidas através do reconhecimento positivo, criando uma rede social onde cada interação gera gratidão, conexões genuínas e bem-estar coletivo."

### 1.2. Problema que Resolve

As redes sociais tradicionais (Instagram, Facebook, Twitter) têm sido associadas a:
- Aumento de ansiedade e depressão
- Comparação social negativa
- FOMO (Fear of Missing Out)
- Superficialidade nas conexões
- Ambiente tóxico e polarizado

O HoloSpot inverte essa dinâmica ao:
- Focar no reconhecimento de outros (não em si mesmo)
- Recompensar ações positivas através de gamificação
- Criar um ambiente seguro e construtivo
- Promover conexões genuínas baseadas em gratidão

### 1.3. Diferencial Único

**"Você não fala sobre você. Você coloca os holofotes nos outros."**

Todo post no HoloSpot é obrigatoriamente sobre outra pessoa. Não é possível criar um post de autopromoção. Essa inversão fundamental muda completamente a dinâmica da rede social.

---

## 2. Conceito Central e Filosofia

### 2.1. Os 4 Efeitos Multiplicadores

Toda interação no HoloSpot é projetada para gerar 4 efeitos positivos:

#### **1. Efeito Cascata**
Quando você reconhece alguém publicamente, essa pessoa se sente valorizada e tende a reconhecer outras pessoas, criando uma cascata de gratidão.

**Exemplo:**
- Maria destaca João por ajudar a equipe
- João se sente valorizado e destaca Ana por ter ensinado algo
- Ana destaca Pedro por ter sido gentil
- Cascata de reconhecimento se espalha

#### **2. Efeito Holofote**
A pessoa destacada recebe visibilidade positiva, aumentando sua autoestima e senso de pertencimento.

**Exemplo:**
- Carlos é tímido e não se promove
- Maria cria post destacando a competência de Carlos
- Toda a rede vê o reconhecimento
- Carlos ganha visibilidade que não teria sozinho

#### **3. Efeito Crescimento**
Ao articular o que você admira em alguém, você desenvolve gratidão e empatia, crescendo como pessoa.

**Exemplo:**
- Ao escrever sobre a paciência de sua professora
- Você reflete sobre a importância da paciência
- Você se torna mais consciente dessa qualidade
- Você cresce emocionalmente

#### **4. Efeito Conexão**
Reconhecimento público fortalece laços sociais e cria conexões autênticas.

**Exemplo:**
- Você destaca um colega de trabalho
- O colega se sente mais conectado a você
- A equipe vê o reconhecimento e também se conecta
- Relacionamentos se fortalecem

### 2.2. Tipos de Reconhecimento

O HoloSpot categoriza reconhecimentos em 6 tipos:

| Tipo | Emoji | Descrição | Exemplo |
|:---|:---:|:---|:---|
| **Gratidão** | 🙏 | Agradecer alguém por algo específico | "Obrigado ao João por ter me ajudado com o projeto" |
| **Conquista** | 🏆 | Celebrar uma conquista de alguém | "Parabéns à Maria por ter fechado a venda!" |
| **Memória** | 💭 | Relembrar um momento especial com alguém | "Lembro quando o Pedro me ensinou a programar..." |
| **Inspiração** | ✨ | Reconhecer alguém que te inspira | "A Ana me inspira pela sua dedicação..." |
| **Apoio** | 🤝 | Reconhecer alguém que te apoiou | "O Carlos sempre está lá quando preciso" |
| **Admiração** | 💖 | Expressar admiração por qualidades de alguém | "Admiro a paciência da professora..." |

---

## 3. Jornada do Usuário Completa

### 3.1. Cadastro e Onboarding

#### **Passo 1: Tela de Boas-Vindas**
- Usuário acessa `holospot.com`
- Vê tela de login/cadastro com gradiente roxo
- Mensagem: "Bem-vindo ao HoloSpot - A rede social do reconhecimento"

#### **Passo 2: Cadastro**
- Usuário clica em "Criar Conta"
- Preenche:
  - Nome completo
  - Email
  - Senha
- Clica em "Cadastrar"

#### **Passo 3: Verificação de Email**
- Supabase envia email de confirmação
- Usuário clica no link de confirmação
- Email é verificado

#### **Passo 4: Completar Perfil**
- Usuário é direcionado para completar perfil:
  - Upload de foto de perfil (opcional)
  - Biografia (opcional)
  - Username é gerado automaticamente do email
- Clica em "Salvar"

#### **Passo 5: Tutorial Interativo**
- Modal de boas-vindas explica:
  - Como criar posts de reconhecimento
  - Como mencionar pessoas
  - Como funciona a gamificação
  - Como ganhar pontos e badges
- Usuário clica em "Começar"

#### **Passo 6: Primeiro Post**
- Interface principal é carregada
- Modal "Criar Seu Primeiro Holofote" é exibido
- Usuário é guiado para criar seu primeiro post
- Ao criar, ganha badge "Primeiro Holofote" + 50 pontos bônus
- Confetes animados celebram a conquista

### 3.2. Uso Diário

#### **Dia 1: Exploração**
- Usuário explora o feed "Para Você"
- Vê posts de outros usuários
- Reage a posts (❤️)
- Comenta em posts
- Ganha pontos por cada interação
- Recebe notificações em tempo real

#### **Dia 2-6: Engajamento**
- Usuário cria mais posts
- Segue pessoas interessantes
- Recebe notificações quando é mencionado
- Acompanha evolução de pontos
- Vê progresso para próximo nível

#### **Dia 7: Primeiro Marco de Streak**
- Usuário completa 7 dias consecutivos de atividade
- Ganha badge "Semana Ativa" + 100 pontos bônus
- Notificação especial celebra o marco
- Usuário se sente motivado a continuar

#### **Dia 30: Engajamento Consolidado**
- Usuário já tem dezenas de posts
- Já conquistou vários badges
- Já subiu alguns níveis
- Já tem uma rede de seguidores
- Já recebeu dezenas de reconhecimentos
- Sente impacto positivo na sua vida

### 3.3. Uso Avançado

#### **Comunidades**
- Usuário é convidado para uma comunidade privada
- Entra na comunidade
- Vê nova aba no feed com emoji da comunidade
- Cria posts exclusivos para a comunidade
- Interage apenas com membros da comunidade

#### **Métricas de Impacto**
- Usuário acessa aba "Impacto"
- Vê gráficos de evolução:
  - Posts criados ao longo do tempo
  - Pontos ganhos por semana
  - Pessoas impactadas
  - Streak de atividade
- Sente orgulho do seu progresso

#### **Chat**
- Usuário quer conversar com alguém
- Clica em "Enviar Mensagem" no perfil
- Abre conversa privada
- Troca mensagens em tempo real
- Recebe notificações de novas mensagens

---

## 4. Funcionalidades Detalhadas

### 4.1. Feed de Atividades

O feed é a tela principal da aplicação e é dividido em **abas dinâmicas**.

#### **Aba: Para Você**

**Propósito:** Feed algorítmico que mostra os posts mais relevantes de toda a rede.

**Algoritmo:**
1. Busca posts globais (community_id = NULL)
2. Prioriza posts recentes (últimas 24 horas)
3. Prioriza posts com mais reações
4. Prioriza posts de pessoas que você segue
5. Mistura posts novos com posts populares
6. Atualiza em tempo real quando novos posts são criados

**Visualização:**
- Card de post com:
  - Foto e nome do autor
  - Tipo de reconhecimento (emoji + texto)
  - Pessoa destacada (@username)
  - Conteúdo do post
  - Foto anexada (se houver)
  - Botões de interação (❤️ Reagir, 💬 Comentar, 🔗 Compartilhar)
  - Contador de reações e comentários

#### **Aba: Seguindo**

**Propósito:** Feed cronológico que exibe apenas os posts das pessoas que você segue.

**Algoritmo:**
1. Busca posts de usuários em `follows` onde `follower_id = auth.uid()`
2. Ordena por `created_at DESC` (mais recente primeiro)
3. Atualiza em tempo real

**Visualização:**
- Mesma estrutura de card do feed "Para Você"
- Se não segue ninguém, mostra mensagem: "Você ainda não segue ninguém. Explore o feed 'Para Você' para encontrar pessoas!"

#### **Abas de Comunidades**

**Propósito:** Feeds privados de comunidades das quais você é membro.

**Comportamento:**
- Para cada comunidade que você participa, uma nova aba é adicionada
- Aba mostra: `[emoji] [nome da comunidade]`
- Exemplo: "🚀 Equipe de Produto"
- Ao clicar na aba, o feed muda para mostrar apenas posts daquela comunidade
- Posts de comunidades NÃO aparecem nos feeds globais

**Algoritmo:**
1. Busca posts onde `community_id = [id da comunidade]`
2. Verifica se você é membro ativo via RLS
3. Ordena por `created_at DESC`
4. Atualiza em tempo real

### 4.2. Criar Post de Reconhecimento

**Acesso:** Botão "✨ Destacar Alguém" no topo do feed

#### **Formulário:**

| Campo | Obrigatório | Descrição |
|:---|:---:|:---|
| **Pessoa a destacar** | ✅ | @username da pessoa (autocomplete ao digitar @) |
| **Tipo de reconhecimento** | ✅ | Dropdown: Gratidão, Conquista, Memória, Inspiração, Apoio, Admiração |
| **Conte sua história** | ✅ | Textarea para o conteúdo do post (mínimo 10 caracteres) |
| **Adicionar foto** | ❌ | Upload de imagem (opcional) |
| **Comunidade** | ❌ | Dropdown (apenas se estiver em uma aba de comunidade) |

#### **Validações:**

1. **Pessoa a destacar:**
   - Deve começar com @
   - Deve existir na tabela `profiles`
   - Autocomplete mostra sugestões ao digitar
   - Não pode destacar a si mesmo

2. **Conteúdo:**
   - Mínimo 10 caracteres
   - Máximo 5000 caracteres
   - Não pode ser apenas espaços em branco

3. **Foto:**
   - Formatos aceitos: JPG, PNG, GIF
   - Tamanho máximo: 5MB
   - Upload para Supabase Storage

#### **Fluxo de Criação:**

1. Usuário preenche formulário
2. Clica em "Publicar"
3. Frontend valida dados
4. Frontend faz upload de foto (se houver)
5. Frontend insere post no banco
6. Triggers automáticos:
   - Concedem pontos ao autor (+10) e mencionado (+5)
   - Verificam badges
   - Criam notificação para mencionado
   - Atualizam streak do autor
7. Post aparece no feed em tempo real
8. Toast de sucesso: "Post criado! +10 pontos"

#### **Recompensas:**

- **Autor:** +10 pontos
- **Mencionado:** +5 pontos
- **Badges possíveis:**
  - "Primeiro Holofote" (primeiro post)
  - "10 Destaques" (10 posts)
  - "50 Destaques" (50 posts)
  - "100 Destaques" (100 posts)
  - "Altruísta" (índice de altruísmo > 2.0)

### 4.3. Interações com Posts

#### **Reagir (❤️)**

**Comportamento:**
- Usuário clica no botão ❤️
- Coração fica vermelho (animação)
- Contador de reações aumenta
- Autor do post recebe +1 ponto
- Autor do post recebe notificação
- Seu streak é atualizado

**Restrições:**
- Só pode reagir uma vez por post
- Pode remover reação clicando novamente
- Ao remover, autor perde o ponto

#### **Comentar (💬)**

**Comportamento:**
- Usuário clica no botão 💬
- Modal de comentários abre
- Usuário digita comentário (mínimo 3 caracteres)
- Clica em "Enviar"
- Comentário aparece na lista
- Autor do post recebe +2 pontos
- Autor do post recebe notificação
- Seu streak é atualizado

**Visualização:**
- Lista de comentários em ordem cronológica
- Cada comentário mostra:
  - Foto e nome do autor
  - Conteúdo do comentário
  - Data (relativa: "há 2 horas")
  - Botão de deletar (se for seu comentário)

#### **Dar Feedback (📝)**

**Diferença de Comentário:**
- Feedback é mais elaborado (mínimo 50 caracteres)
- Concede +3 pontos ao autor do post (vs +2 do comentário)
- Aparece em seção separada "Feedbacks"

**Comportamento:**
- Usuário clica em "Dar Feedback"
- Modal abre com textarea maior
- Usuário escreve feedback detalhado
- Clica em "Enviar Feedback"
- Autor do post recebe +3 pontos
- Autor do post recebe notificação

#### **Compartilhar (🔗)**

**Comportamento:**
- Usuário clica no botão 🔗
- Modal abre com opções:
  - **Copiar Link:** Copia URL única do post (`holospot.com/?post=abc123`)
  - **Compartilhar no WhatsApp:** Abre WhatsApp com link
  - **Compartilhar no Twitter:** Abre Twitter com link
  - **Compartilhar no LinkedIn:** Abre LinkedIn com link
- Link copiado → Toast de sucesso

**URL Gerada:**
- Formato: `https://holospot.com/?post=[post_id]`
- Ao acessar, carrega página dedicada do post
- Meta tags Open Graph para preview bonito no WhatsApp/Twitter

### 4.4. Perfil de Usuário

**Acesso:**
- Clicando no nome/foto de qualquer usuário
- Clicando em "Meu Perfil" na sidebar
- URL direta: `holospot.com/?profile=username`

#### **Seções do Perfil:**

##### **1. Header**
- Foto de perfil (grande)
- Nome completo
- @username
- Botões:
  - "Seguir" / "Deixar de Seguir"
  - "Enviar Mensagem"
  - "Compartilhar Perfil"
- Estatísticas rápidas:
  - Nível atual
  - Pontos totais
  - Seguidores / Seguindo

##### **2. Sobre**
- Biografia
- Data de entrada ("Membro desde...")
- Localização (se preenchida)

##### **3. Badges Conquistados**
- Grid de badges com emojis
- Badges desbloqueados coloridos
- Badges bloqueados em cinza
- Hover mostra descrição e data de conquista

##### **4. Posts Criados**
- Tab: "Posts que Criei" (posts onde `user_id = perfil`)
- Grid de cards de posts
- Ordenados por data (mais recente primeiro)

##### **5. Posts Recebidos**
- Tab: "Posts que Recebi" (posts onde `celebrated_person_name = @perfil`)
- Grid de cards de posts
- Mostra todos os reconhecimentos que a pessoa recebeu

##### **6. Métricas de Impacto**
- Gráfico de evolução de pontos
- Gráfico de posts criados ao longo do tempo
- Estatísticas:
  - Total de pessoas impactadas
  - Streak atual
  - Maior streak
  - Posts criados
  - Reações dadas
  - Comentários feitos

### 4.5. Sistema de Seguidores

**Propósito:** Criar uma rede de conexões para personalizar o feed "Seguindo".

#### **Seguir Alguém:**
1. Usuário acessa perfil de outra pessoa
2. Clica em "Seguir"
3. Botão muda para "Seguindo"
4. Registro criado em `follows`:
   - `follower_id`: você
   - `following_id`: pessoa seguida
5. Pessoa seguida recebe notificação
6. Posts da pessoa aparecem no seu feed "Seguindo"

#### **Deixar de Seguir:**
1. Usuário clica em "Seguindo"
2. Modal de confirmação: "Tem certeza?"
3. Usuário confirma
4. Registro deletado de `follows`
5. Posts da pessoa param de aparecer no feed "Seguindo"

#### **Visualizar Seguidores/Seguindo:**
- Clicando em "X Seguidores" ou "X Seguindo" no perfil
- Modal abre com lista de usuários
- Cada usuário mostra:
  - Foto
  - Nome
  - @username
  - Botão "Ver Perfil"
  - Botão "Seguir" / "Seguindo"

---

## 5. Sistema de Gamificação Completo

A gamificação é o motor que incentiva o engajamento positivo. O sistema é composto por 4 pilares: **Pontos**, **Badges**, **Níveis** e **Streaks**.

### 5.1. Sistema de Pontos

#### **Tabela de Pontuação:**

| Ação | Pontos para Você | Pontos para Outros | Descrição |
|:---|:---:|:---:|:---|
| **Criar post de reconhecimento** | +10 | +5 (mencionado) | Você ganha por criar, mencionado ganha por ser reconhecido |
| **Receber reação no seu post** | +1 | - | Cada ❤️ que você recebe |
| **Receber comentário no seu post** | +2 | - | Cada comentário que você recebe |
| **Dar feedback em um post** | +3 | - | Feedback é mais elaborado que comentário |
| **Conquistar um badge** | Bônus variável | - | Cada badge concede pontos bônus (50-500) |
| **Atingir marco de streak** | Bônus variável | - | 7 dias: +100, 30 dias: +500, etc. |
| **Subir de nível** | - | - | Não concede pontos, mas desbloqueia badges |

#### **Pontos Negativos:**

| Ação | Penalidade |
|:---|:---:|
| **Deletar um post** | -10 (você) e -5 (mencionado) |
| **Remover uma reação** | -1 (autor do post) |
| **Deletar um comentário** | -2 (autor do post) |

#### **Visualização de Pontos:**

- **Header:** Sempre visível no topo ("⭐ 1.234 pontos")
- **Perfil:** Seção de estatísticas
- **Notificações:** Toast ao ganhar pontos ("+ 10 pontos!")
- **Histórico:** Aba "Impacto" mostra histórico completo

### 5.2. Badges (Conquistas)

O HoloSpot possui **20+ badges** organizados em **5 categorias**.

#### **Categoria: Iniciante (Primeiras Ações)**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **Primeiro Holofote** | 🌟 | Criar primeiro post | +50 |
| **Primeira Reação** | ❤️ | Dar primeira reação | +10 |
| **Primeiro Comentário** | 💬 | Fazer primeiro comentário | +20 |
| **Primeiro Seguidor** | 👥 | Receber primeiro seguidor | +30 |
| **Primeiro Feedback** | 📝 | Dar primeiro feedback | +30 |

#### **Categoria: Engajamento (Consistência)**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **10 Destaques** | 🎯 | Criar 10 posts | +100 |
| **50 Destaques** | 🏅 | Criar 50 posts | +250 |
| **100 Destaques** | 🏆 | Criar 100 posts | +500 |
| **Engajador** | 🔥 | Dar 100+ reações | +200 |
| **Comentarista** | 💭 | Fazer 50+ comentários | +150 |

#### **Categoria: Social (Rede de Conexões)**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **10 Seguidores** | 👥 | Ter 10 seguidores | +100 |
| **50 Seguidores** | 🌐 | Ter 50 seguidores | +250 |
| **Influenciador** | ⭐ | Ter 100+ seguidores | +500 |
| **Networker** | 🤝 | Seguir 50+ pessoas | +100 |

#### **Categoria: Streaks (Consistência Diária)**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **Semana Ativa** | 🔥 | 7 dias consecutivos | +100 |
| **Mês Ativo** | 📅 | 30 dias consecutivos | +500 |
| **Semestre Ativo** | 🎖️ | 182 dias consecutivos | +2000 |
| **Ano Ativo** | 👑 | 365 dias consecutivos | +5000 |

#### **Categoria: Comunidades**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **Owner de Comunidade** | 👑 | Criar uma comunidade | +500 |
| **Membro de Comunidade** | 🏢 | Entrar em uma comunidade | +50 |
| **Primeiro Post em Comunidade** | 🎯 | Criar primeiro post em comunidade | +100 |

#### **Categoria: Especiais (Métricas Avançadas)**

| Badge | Emoji | Condição | Bônus |
|:---|:---:|:---|:---:|
| **Altruísta** | 💖 | Índice de altruísmo > 2.0 | +300 |
| **Inspirador** | ✨ | Receber 50+ posts de reconhecimento | +400 |

**Índice de Altruísmo:**
```
Altruísmo = (Posts Criados) / (Posts Recebidos)
```
- Se você cria mais posts do que recebe, você é altruísta
- Exemplo: 20 posts criados / 10 posts recebidos = 2.0 (altruísta!)

#### **Visualização de Badges:**

- **Perfil:** Grid de badges (coloridos se conquistados, cinza se bloqueados)
- **Notificação:** Toast animado ao conquistar ("🎉 Novo Badge: 10 Destaques!")
- **Modal:** Detalhes do badge (descrição, data de conquista, bônus)

### 5.3. Níveis de Progressão

O HoloSpot possui **10 níveis** que representam a jornada do usuário.

| Nível | Nome | Pontos Necessários | Descrição |
|:---:|:---|:---:|:---|
| **1** | Iniciante | 0 | Você está começando sua jornada |
| **2** | Aprendiz | 100 | Você está aprendendo a reconhecer |
| **3** | Praticante | 300 | Você pratica reconhecimento regularmente |
| **4** | Engajado | 600 | Você está engajado na comunidade |
| **5** | Dedicado | 1.000 | Você é dedicado ao reconhecimento |
| **6** | Experiente | 1.500 | Você tem experiência em reconhecer |
| **7** | Mestre | 2.500 | Você é mestre em reconhecimento |
| **8** | Inspirador | 4.000 | Você inspira outros a reconhecer |
| **9** | Líder | 6.000 | Você é líder em reconhecimento |
| **10** | Lenda | 10.000 | Você é uma lenda do HoloSpot! |

#### **Cálculo de Nível:**

O nível é calculado automaticamente baseado nos pontos totais:
```sql
SELECT level FROM levels 
WHERE points_required <= [seus_pontos_totais] 
ORDER BY points_required DESC 
LIMIT 1;
```

#### **Notificação de Level Up:**

Quando você sobe de nível:
1. Notificação especial: "🎊 Parabéns! Você subiu para o nível X: [Nome do Nível]"
2. Animação de confetes na tela
3. Som de celebração (se habilitado)
4. Badge de nível desbloqueado (se houver)

#### **Visualização de Nível:**

- **Header:** Badge de nível ao lado do nome ("Nível 5 - Dedicado")
- **Perfil:** Seção de estatísticas com barra de progresso
- **Barra de Progresso:**
  ```
  Nível 5: Dedicado
  [████████░░] 1.234 / 1.500 pontos
  Faltam 266 pontos para o próximo nível
  ```

### 5.4. Streaks de Atividade

**Definição:** Um streak é contado para cada dia consecutivo que você realiza **pelo menos uma atividade** na plataforma.

#### **Atividades que Contam para Streak:**
- Criar post
- Comentar em post
- Reagir a post
- Dar feedback em post

#### **Cálculo de Streak:**

O sistema:
1. Coleta todas as suas atividades
2. Agrupa por data (convertida para seu timezone)
3. Ordena datas de forma decrescente
4. Começa de hoje e vai para trás, contando dias consecutivos
5. Para no primeiro dia sem atividade
6. Se hoje não tem atividade, streak = 0

**Exemplo:**
```
Hoje: 30/10/2025 (tem atividade) ✓
29/10/2025 (tem atividade) ✓
28/10/2025 (tem atividade) ✓
27/10/2025 (SEM atividade) ✗

Streak atual: 3 dias
```

#### **Marcos de Streak:**

| Marco | Dias | Bônus | Badge |
|:---|:---:|:---:|:---|
| **Semana Ativa** | 7 | +100 | 🔥 |
| **Mês Ativo** | 30 | +500 | 📅 |
| **Semestre Ativo** | 182 | +2000 | 🎖️ |
| **Ano Ativo** | 365 | +5000 | 👑 |

#### **Visualização de Streak:**

- **Header:** Ícone de fogo com número ("🔥 12 dias")
- **Perfil:** Seção de estatísticas
  ```
  Streak Atual: 12 dias 🔥
  Maior Streak: 45 dias
  
  Progresso para Próximo Marco:
  [████████░░] 12 / 30 dias (Mês Ativo)
  Faltam 18 dias
  ```

#### **Notificação de Marco:**

Quando você atinge um marco:
1. Notificação especial: "🔥 Parabéns! Você completou 7 dias consecutivos!"
2. Badge desbloqueado: "Semana Ativa"
3. Pontos bônus concedidos: +100
4. Animação de fogo na tela

---

## 6. Comunidades Privadas

Comunidades são **espaços privados** dentro do HoloSpot para grupos específicos (empresas, equipes, famílias, clubes) se conectarem de forma mais focada.

### 6.1. O que são Comunidades

**Definição:** Uma comunidade é um grupo fechado de usuários que compartilham um feed privado de reconhecimentos.

**Características:**
- **Privacidade:** Apenas membros veem posts da comunidade
- **Isolamento:** Posts de comunidades NÃO aparecem nos feeds globais
- **Personalização:** Cada comunidade tem nome, emoji, logo e descrição
- **Moderação:** O dono da comunidade pode adicionar/remover membros e moderar posts

### 6.2. Criação de Comunidades

**Controle de Acesso:** A criação de comunidades é **controlada**. Apenas usuários com `community_owner = TRUE` podem criar.

**Atualmente:** Apenas `@guilherme.dutra` pode criar comunidades.

#### **Fluxo de Criação:**

1. @guilherme.dutra clica em "🏢 Gerenciar Comunidades"
2. Modal abre com lista de comunidades existentes
3. Clica em "Criar Nova Comunidade"
4. Preenche formulário:
   - **Nome:** "Equipe de Produto"
   - **Slug:** "equipe-produto" (URL amigável)
   - **Descrição:** "Comunidade da equipe de produto para reconhecimentos internos"
   - **Emoji:** 🚀 (clica em "Escolher Emoji" → emoji picker)
   - **Logo:** URL da imagem (opcional)
5. Clica em "Criar Comunidade"
6. Backend:
   - Verifica se é `community_owner`
   - Cria registro em `communities`
   - Adiciona criador como membro com `role = 'owner'`
   - Concede badge "Owner de Comunidade" + 500 pontos
7. Nova aba aparece no feed: "🚀 Equipe de Produto"

### 6.3. Gerenciamento de Membros

**Acesso:** Apenas o dono da comunidade pode gerenciar membros.

#### **Adicionar Membro:**

1. Dono clica em "Gerenciar Comunidades"
2. Seleciona comunidade
3. Clica em "Adicionar Membro"
4. Busca usuário por nome ou @username
5. Seleciona usuário
6. Clica em "Adicionar"
7. Backend:
   - Verifica se é owner da comunidade
   - Cria registro em `community_members` com `role = 'member'`
   - Concede badge "Membro de Comunidade" ao novo membro + 50 pontos
8. Novo membro vê nova aba no feed

#### **Remover Membro:**

1. Dono clica em "Gerenciar Comunidades"
2. Seleciona comunidade
3. Vê lista de membros
4. Clica em "Remover" ao lado do membro
5. Modal de confirmação: "Tem certeza?"
6. Confirma
7. Backend:
   - Verifica se é owner
   - Atualiza `is_active = FALSE` em `community_members`
8. Membro perde acesso ao feed da comunidade

### 6.4. Feed de Comunidade

**Comportamento:**

- Ao clicar na aba da comunidade, o feed muda para mostrar apenas posts daquela comunidade
- Botão "✨ Destacar Alguém" agora cria posts **exclusivos** para aquela comunidade
- Posts de comunidades têm badge visual: "🏢 [Nome da Comunidade]"
- Apenas membros ativos podem ver os posts

**Segurança (RLS):**
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

### 6.5. Moderação

**Privilégios do Owner:**

- **Editar qualquer post** da comunidade (mesmo que não seja autor)
- **Deletar qualquer post** da comunidade
- **Adicionar/remover membros**
- **Editar informações da comunidade** (nome, descrição, emoji, logo)
- **Desativar comunidade** (todos os membros perdem acesso)

**Política de RLS:**
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

### 6.6. Gamificação em Comunidades

**Badges Específicos:**
- **Owner de Comunidade:** Criar uma comunidade (+500 pontos)
- **Membro de Comunidade:** Entrar em uma comunidade (+50 pontos)
- **Primeiro Post em Comunidade:** Criar primeiro post em comunidade (+100 pontos)

**Pontos:**
- Posts em comunidades concedem os mesmos pontos que posts globais
- Pontos são unificados (não separados por comunidade)

**Níveis:**
- Níveis são globais (não separados por comunidade)

---

## 7. Notificações e Tempo Real

O HoloSpot possui um sistema robusto de notificações em tempo real que mantém os usuários informados sobre todas as interações relevantes.

### 7.1. Tipos de Notificações

| Tipo | Emoji | Gatilho | Mensagem Exemplo |
|:---|:---:|:---|:---|
| **holofote** | 🌟 | Alguém te destaca em um post | "Maria te destacou em um post!" |
| **reaction** | ❤️ | Alguém reage ao seu post | "João reagiu ao seu post" |
| **comment** | 💬 | Alguém comenta no seu post | "Ana comentou no seu post" |
| **follow** | 👥 | Alguém começa a te seguir | "Pedro começou a te seguir" |
| **badge** | 🏆 | Você desbloqueia um badge | "Parabéns! Você conquistou: 10 Destaques" |
| **level_up** | 🎊 | Você sobe de nível | "Você subiu para o nível 5: Dedicado" |
| **streak** | 🔥 | Você atinge marco de streak | "Você completou 7 dias consecutivos!" |

### 7.2. Visualização de Notificações

#### **Ícone de Notificações (Header):**
- Sino com contador: "🔔 (3)"
- Badge vermelho se houver não lidas
- Animação de "shake" ao receber nova notificação

#### **Painel de Notificações:**
- Clicando no sino, abre painel lateral
- Lista de notificações em ordem cronológica (mais recente primeiro)
- Cada notificação mostra:
  - Emoji do tipo
  - Foto do usuário que gerou (se aplicável)
  - Mensagem
  - Tempo relativo ("há 2 horas")
  - Indicador de lida/não lida (bolinha azul)
- Botões:
  - "Marcar todas como lidas"
  - "Ver todas"

#### **Notificações em Tempo Real:**

O sistema usa **Supabase Realtime (WebSockets)** para entregar notificações instantaneamente:

```javascript
supabase
  .channel('notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${currentUser.id}`
  }, payload => {
    // Nova notificação recebida!
    showToast(payload.new.message);
    playNotificationSound();
    updateNotificationBadge();
  })
  .subscribe();
```

### 7.3. Anti-Spam de Notificações

Para evitar spam, o sistema possui a função `check_notification_spam()` que:

1. Verifica se já existe notificação idêntica criada nas últimas **1 hora**
2. Se existe, **não cria** nova notificação
3. Caso contrário, cria normalmente

**Exemplo:**
- João reage ao seu post às 10:00 → Notificação criada ✓
- João remove reação às 10:05 → Notificação não é deletada
- João reage novamente às 10:10 → Notificação NÃO é criada (spam) ✗
- João reage novamente às 11:05 → Notificação criada ✓ (passou 1 hora)

### 7.4. Prioridade de Notificações

Notificações possuem níveis de prioridade (1-5):

| Prioridade | Tipos | Comportamento |
|:---:|:---|:---|
| **5** | badge, level_up, streak | Som especial, animação, toast destacado |
| **3** | holofote, follow | Som normal, toast normal |
| **1** | reaction, comment | Sem som, apenas contador |

---

## 8. Métricas e Impacto

A aba "Impacto" mostra métricas detalhadas sobre sua jornada no HoloSpot.

### 8.1. Visão Geral

**Seção: Resumo**

Cards com estatísticas principais:
- **Pontos Totais:** 1.234 ⭐
- **Nível Atual:** 5 - Dedicado
- **Streak Atual:** 12 dias 🔥
- **Posts Criados:** 45
- **Pessoas Impactadas:** 32

### 8.2. Gráficos de Evolução

#### **Gráfico: Pontos ao Longo do Tempo**

- Tipo: Linha
- Eixo X: Tempo (últimos 30 dias)
- Eixo Y: Pontos acumulados
- Tooltip: Mostra pontos exatos em cada data
- Permite ver crescimento da pontuação

#### **Gráfico: Posts Criados por Semana**

- Tipo: Barra
- Eixo X: Semanas (últimas 12 semanas)
- Eixo Y: Quantidade de posts
- Tooltip: Mostra quantidade exata
- Permite ver consistência de criação

#### **Gráfico: Distribuição de Tipos de Reconhecimento**

- Tipo: Pizza (Donut)
- Mostra % de cada tipo:
  - Gratidão: 30%
  - Conquista: 20%
  - Inspiração: 15%
  - Apoio: 15%
  - Memória: 10%
  - Admiração: 10%

### 8.3. Métricas Avançadas

**Índice de Altruísmo:**
```
Altruísmo = (Posts Criados) / (Posts Recebidos)
```
- Visualização: Medidor de 0 a 5
- Interpretação:
  - < 1.0: Você recebe mais do que dá
  - 1.0: Equilíbrio perfeito
  - > 2.0: Você é altruísta! (badge desbloqueado)

**Pessoas Impactadas:**
- Contagem de usuários únicos que você destacou
- Lista de pessoas com fotos
- Clicável para ver perfil

**Engajamento Recebido:**
- Total de reações recebidas
- Total de comentários recebidos
- Total de feedbacks recebidos
- Média de engajamento por post

### 8.4. Histórico de Pontos

**Tabela Detalhada:**

| Data | Ação | Pontos | Total |
|:---|:---|:---:|:---:|
| 30/10 10:30 | Post criado | +10 | 1.234 |
| 30/10 09:15 | Reação recebida | +1 | 1.224 |
| 29/10 18:45 | Badge: 10 Destaques | +100 | 1.223 |
| 29/10 14:20 | Comentário recebido | +2 | 1.123 |

- Paginação: 20 registros por página
- Filtros: Por tipo de ação, por data
- Exportação: CSV (futuro)

---

## 9. Chat e Mensagens Diretas

O HoloSpot possui um sistema de chat para conversas privadas entre usuários.

### 9.1. Iniciar Conversa

**Acesso:**
- Clicando em "Enviar Mensagem" no perfil de qualquer usuário
- Clicando em uma conversa existente na aba "Chat"

**Comportamento:**
1. Sistema verifica se já existe conversa entre os dois usuários
2. Se existe, abre conversa existente
3. Se não existe, cria nova conversa
4. Abre interface de chat

### 9.2. Interface de Chat

**Layout:**

```
┌─────────────────────────────────────────┐
│ [←] João Silva                    [⋮]   │ ← Header
├─────────────────────────────────────────┤
│                                         │
│  Olá! Como vai?              [João]     │ ← Mensagem recebida
│  10:30                                  │
│                                         │
│                    [Você] Oi! Tudo bem? │ ← Mensagem enviada
│                                  10:32  │
│                                         │
│  Queria te agradecer...      [João]     │
│  10:35                                  │
│                                         │
├─────────────────────────────────────────┤
│ [Digite sua mensagem...]         [Enviar]│ ← Input
└─────────────────────────────────────────┘
```

**Características:**
- Mensagens em tempo real (WebSockets)
- Scroll automático para última mensagem
- Indicador de "digitando..." (futuro)
- Indicador de mensagem lida (futuro)

### 9.3. Enviar Mensagem

**Comportamento:**
1. Usuário digita mensagem
2. Pressiona Enter ou clica em "Enviar"
3. Frontend valida (mínimo 1 caractere)
4. Frontend insere em `messages`:
   - `conversation_id`: ID da conversa
   - `sender_id`: Seu ID
   - `content`: Conteúdo da mensagem
5. Mensagem aparece instantaneamente na sua interface
6. Destinatário recebe via Realtime
7. Mensagem aparece na interface do destinatário
8. Notificação push (se habilitada)

### 9.4. Lista de Conversas

**Aba "Chat" na Sidebar:**

- Lista de conversas ordenadas por última mensagem
- Cada conversa mostra:
  - Foto do outro usuário
  - Nome do outro usuário
  - Prévia da última mensagem (50 caracteres)
  - Tempo relativo ("há 2 horas")
  - Badge de mensagens não lidas (se houver)
- Clicável para abrir conversa

---

## 10. Compartilhamento e URLs

O HoloSpot possui URLs únicas e compartilháveis para posts e perfis, facilitando o compartilhamento fora da plataforma.

### 10.1. URLs de Posts

**Formato:** `https://holospot.com/?post=[post_id]`

**Exemplo:** `https://holospot.com/?post=abc123-def456-ghi789`

#### **Comportamento ao Acessar:**

1. Browser carrega `holospot.com/?post=abc123`
2. Frontend detecta parâmetro `?post=` na inicialização
3. Frontend chama `PostRouter.showFullPost('abc123')`
4. Interface principal é ocultada
5. Container `fullPostContainer` é exibido
6. Frontend carrega dados do post via API
7. Página dedicada do post é renderizada com:
   - Header com logo e botão "Fechar"
   - Foto e nome do autor
   - Tipo de reconhecimento
   - Pessoa destacada
   - Conteúdo completo do post
   - Foto anexada (se houver)
   - Reações e comentários
   - Botões de interação (se logado)
   - Meta tags Open Graph para preview bonito

#### **Meta Tags Open Graph:**

```html
<meta property="og:title" content="Maria destacou João no HoloSpot" />
<meta property="og:description" content="João sempre ajuda a equipe..." />
<meta property="og:image" content="https://...foto-do-post.jpg" />
<meta property="og:url" content="https://holospot.com/?post=abc123" />
```

**Resultado:** Preview bonito ao compartilhar no WhatsApp, Twitter, LinkedIn, etc.

### 10.2. URLs de Perfis

**Formato:** `https://holospot.com/?profile=[username]`

**Exemplo:** `https://holospot.com/?profile=joao.silva`

#### **Comportamento ao Acessar:**

1. Browser carrega `holospot.com/?profile=joao.silva`
2. Frontend detecta parâmetro `?profile=` na inicialização
3. Frontend chama `ProfileRouter.showFullProfile('joao.silva')`
4. Interface principal é ocultada
5. Container `fullProfileContainer` é exibido
6. Frontend busca usuário por username
7. Página dedicada do perfil é renderizada com:
   - Header com logo e botão "Fechar"
   - Foto de perfil grande
   - Nome completo e @username
   - Biografia
   - Estatísticas (pontos, nível, seguidores)
   - Badges conquistados
   - Posts criados e recebidos
   - Botões "Seguir" e "Enviar Mensagem" (se logado)

#### **Meta Tags Open Graph:**

```html
<meta property="og:title" content="João Silva (@joao.silva) - HoloSpot" />
<meta property="og:description" content="Nível 5 - Dedicado | 1.234 pontos" />
<meta property="og:image" content="https://...avatar-joao.jpg" />
<meta property="og:url" content="https://holospot.com/?profile=joao.silva" />
```

### 10.3. Compartilhamento Social

**Botão "Compartilhar" em Posts:**

Modal com opções:
- **Copiar Link:** Copia URL para clipboard
- **WhatsApp:** `https://wa.me/?text=[URL do post]`
- **Twitter:** `https://twitter.com/intent/tweet?url=[URL do post]&text=[Mensagem]`
- **LinkedIn:** `https://www.linkedin.com/sharing/share-offsite/?url=[URL do post]`
- **Facebook:** `https://www.facebook.com/sharer/sharer.php?u=[URL do post]`

**Botão "Compartilhar Perfil":**

Modal com opções:
- **Copiar Link:** Copia URL do perfil
- **WhatsApp:** Compartilha perfil no WhatsApp
- **Email:** Abre cliente de email com link

---

## 11. Considerações Finais

Este documento funcional fornece uma visão completa de TODAS as funcionalidades do HoloSpot. Para usuários, stakeholders ou desenvolvedores que precisam entender a plataforma:

1. **Leia este documento completamente** para entender a filosofia e mecânicas
2. **Experimente a plataforma** para ver as funcionalidades em ação
3. **Consulte o README_TECHNICAL.md** para detalhes de implementação
4. **Forneça feedback** para melhorias contínuas

O HoloSpot é mais do que uma rede social. É um movimento para transformar a forma como nos conectamos online, colocando o reconhecimento e o bem-estar no centro da experiência.

---

**Autor:** Manus AI  
**Última Atualização:** 30 de outubro de 2025  
**Versão do Documento:** 2.0
