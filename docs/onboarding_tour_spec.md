# Planejamento: Tour de Onboarding para Novos Usuários

**Autor**: Manus AI
**Data**: 12 de janeiro de 2026
**Versão**: 1.0

## 1. Visão Geral

Este documento detalha o planejamento para a implementação de um sistema de **tour de onboarding guiado por tooltips** na rede social HoloSpot. O objetivo é apresentar as funcionalidades principais da plataforma para novos usuários no seu primeiro acesso, melhorando a experiência inicial e acelerando a curva de aprendizado.

O tour será uma sequência de dicas contextuais que destacam os elementos-chave da interface, explicando o propósito de cada um. O usuário terá a opção de seguir o tour passo a passo ou pulá-lo a qualquer momento.

## 2. Conceito e Experiência do Usuário

O tour será **sugerido** automaticamente **apenas na primeira vez** que o usuário acessa o site após completar seu cadastro. Além disso, um botão no modal de configurações permitirá que o usuário inicie o tour a qualquer momento. Uma biblioteca de JavaScript, como a **Shepherd.js**, será usada para criar os tooltips e o efeito de sobreposição que foca em um elemento da UI por vez.

### Fluxo do Usuário

1.  **Gatilho Automático**: Após a finalização do cadastro, na primeira vez que o usuário é redirecionado para a página principal, o sistema verifica se ele já completou o tour. Se não, um modal de sugestão aparece.
2.  **Gatilho Manual**: No modal de configurações do usuário, haverá um botão "Ver Tour Guiado" que inicia o tour a qualquer momento.
3.  **Sugestão**: O modal de sugestão pergunta: "Você gostaria de fazer um tour rápido para conhecer a plataforma?". Botões: "Sim, vamos lá!" e "Agora não".
4.  **Sequência**: Ao aceitar, o tour começa com o primeiro tooltip. O usuário pode navegar com os botões "Próximo" e "Anterior".
5.  **Finalização**: Ao concluir, o sistema marca o tour como completo para que a sugestão automática não apareça novamente.
6.  **Pular/Fechar**: Se o usuário pular, fechar o modal de sugestão ou fechar um tooltip, o tour é marcado como concluído para não ser sugerido novamente.

## 3. Especificação Técnica

A implementação será dividida em três frentes: Banco de Dados, Backend (Funções SQL) e Frontend (JavaScript).

### 3.1. Banco de Dados

Para rastrear quais usuários já viram o tour, uma nova coluna será adicionada à tabela `profiles`.

| Tabela   | Coluna                      | Tipo    | Padrão | Descrição                                        |
| :------- | :-------------------------- | :------ | :----- | :------------------------------------------------- |
| `profiles` | `has_completed_onboarding`  | BOOLEAN | `false`  | `true` se o usuário completou ou pulou o tour. |

**SQL para Migração:**

```sql
-- Adicionar coluna para rastrear o status do onboarding
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.has_completed_onboarding IS
'Indica se o usuário já completou (ou pulou) o tour de onboarding inicial.';
```

### 3.2. Backend (Funções SQL)

Uma função RPC (Remote Procedure Call) será criada para permitir que o frontend atualize o status do onboarding de forma segura.

**Função `set_onboarding_completed()`**

-   **Propósito**: Marcar o tour de onboarding como concluído para o usuário autenticado.
-   **Parâmetros**: Nenhum (usa `auth.uid()` para identificar o usuário).
-   **Retorno**: `void`

**SQL da Função:**

```sql
CREATE OR REPLACE FUNCTION public.set_onboarding_completed()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE public.profiles
  SET has_completed_onboarding = true
  WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION public.set_onboarding_completed() TO authenticated;
```

### 3.3. Frontend (JavaScript)

O frontend será responsável por orquestrar toda a lógica do tour.

**1. Instalação da Biblioteca**

-   A biblioteca **Shepherd.js** será utilizada. Seus arquivos CSS e JS serão adicionados ao `index.html` via CDN para uma instalação rápida.

    ```html
    <!-- No <headdo index.html -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/shepherd.js@10.0.1/dist/css/shepherd.css"/>

    <!-- Antes de fechar o </body-->
    <script src="https://cdn.jsdelivr.net/npm/shepherd.js@10.0.1/dist/js/shepherd.min.js"></script>
    ```

**2. Lógica de Acionamento**

-   **Gatilho Automático**: Na inicialização da aplicação, verificar se `currentUser.has_completed_onboarding` é `false`. Se for, exibir o modal de sugestão.
-   **Gatilho Manual**: Adicionar um botão no modal de configurações (`#settingsModal`) que chama diretamente a função `startOnboardingTour()`.

**3. Definição dos Passos do Tour**

-   Uma função `startOnboardingTour()` conterá a configuração e a sequência de todos os tooltips. Cada passo será um objeto com `target` (seletor CSS), `title` e `text`.

**4. Persistência do Estado**

-   **Persistência do Estado**: A função RPC `supabaseClient.rpc(\'set_onboarding_completed\')` será chamada nos seguintes cenários:
    -   Ao clicar em "Concluir" no último passo do tour.
    -   Ao clicar em "Pular" em qualquer tooltip.
    -   Ao clicar em "Agora não" no modal de sugestão inicial.
    -   Ao fechar qualquer tooltip ou o modal de sugestão.

## 4. Conteúdo do Tour: Roteiro de Passos

A sequência de passos foi desenhada para introduzir as funcionalidades de forma lógica e progressiva.

| Passo | Título                      | Elemento Alvo (CSS Selector) | Conteúdo do Tooltip                                                                                             |
| :---- | :-------------------------- | :--------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **1** | Bem-vindo(a) ao HoloSpot!   | (Nenhum - Modal Central)     | "Vamos fazer um tour rápido para você conhecer as principais funcionalidades da nossa rede. Leva só um minuto!"     |
| **2** | Seu Feed Principal          | `#feedTab`                   | "Aqui você vê as publicações das pessoas e comunidades que segue. É a sua central de novidades."                  |
| **3** | Destaque Alguém!            | `#destacarTab`               | "Nesta aba, você cria posts especiais para destacar pessoas, expressar gratidão, compartilhar memórias e muito mais." |
| **4.a** | Tipos de Destaque         | `#highlightTypesGrid`        | "Escolha um tipo de destaque para dar um propósito ao seu post. Cada um tem um significado especial."             |
| **4.b** | Crie uma Corrente           | `#createChainBtn`            | "Transforme seu post no início de uma corrente! Convide outros a continuarem a história com o mesmo tema."        |
| **5** | Seu Perfil e Conquistas     | `#profileTab`                | "Acesse seu perfil, veja suas estatísticas, badges conquistados e gerencie suas configurações."                  |
| **6** | Notificações                | `#notificationsBtn`          | "Fique por dentro de tudo que acontece. Aqui você vê reações, novos seguidores e outras interações."             |
| **7** | Tudo Pronto!                | (Nenhum - Modal Central)     | "Você concluiu o tour! Agora é sua vez de explorar, conectar e destacar as pessoas incríveis ao seu redor."      |

## 5. Cronograma de Implementação (Estimativa)

A implementação pode ser dividida nas seguintes fases:

| Fase | Tarefa                                                 | Tempo Estimado |
| :--- | :----------------------------------------------------- | :------------- |
| **1** | **Backend**: Adicionar coluna e criar função RPC         | 1.0 hora       |
| **2** | **Frontend**: Instalar Shepherd.js e configurar o básico | 0.5 horas      |
| **3** | **Frontend**: Implementar a lógica dos 7 passos do tour  | 2.5 horas      |
| **4** | **Frontend**: Criar modal de sugestão e gatilho automático | 1.5 horas      |
| **5** | **Frontend**: Adicionar botão no modal de configurações    | 0.5 horas      |
| **6** | **Testes**: Testar ambos os gatilhos e o fluxo completo  | 1.0 hora       |
|      | **Total**                                              | **7.0 horas**  |
