# 🧪 CHECKLIST DE TESTES - SISTEMA DE CORRENTES

**Versão:** 1.0  
**Data:** 04 de Dezembro de 2025  
**Status:** Implementação Completa

---

## 📋 RESUMO DA IMPLEMENTAÇÃO

### ✅ FASES CONCLUÍDAS:

1. **FASE 1:** Banco de Dados (tabelas, índices, RLS)
2. **FASE 2:** Funções SQL (create, cancel, add, get, close)
3. **FASE 3:** Frontend de Criação
4. **FASE 4:** Frontend de Participação
5. **FASE 5:** Integração com Posts
6. **FASE 6:** Gamificação (badges e pontuação)

---

## 🧪 TESTES FUNCIONAIS

### 1. CRIAÇÃO DE CORRENTE

#### 1.1. Abrir Modal de Criação
- [ ] Ir para aba "Destacar"
- [ ] Verificar se botão "Criar Corrente 🔗" aparece no canto superior direito
- [ ] Clicar no botão
- [ ] Modal "Criar Corrente 🔗" deve abrir

#### 1.2. Validações do Formulário
- [ ] Tentar criar com nome vazio → Deve mostrar erro
- [ ] Tentar criar com nome < 3 caracteres → Deve mostrar erro
- [ ] Tentar criar com descrição vazia → Deve mostrar erro
- [ ] Tentar criar com descrição < 10 caracteres → Deve mostrar erro
- [ ] Tentar criar sem selecionar tipo → Deve mostrar erro

#### 1.3. Criar Corrente com Sucesso
- [ ] Preencher nome: "Corrente de Teste"
- [ ] Preencher descrição: "Esta é uma corrente de teste para validação"
- [ ] Selecionar tipo: "Gratidão"
- [ ] Clicar em "Criar Corrente"
- [ ] Modal deve fechar
- [ ] Notificação de sucesso deve aparecer
- [ ] Botão "Criar Corrente" deve ser substituído por nome + "Cancelar Corrente"
- [ ] Tipo "Gratidão" deve ficar fixado (outros desabilitados)

#### 1.4. Tooltip da Corrente
- [ ] Passar mouse sobre o nome da corrente
- [ ] Tooltip deve aparecer mostrando a descrição
- [ ] Tooltip deve seguir o mouse

#### 1.5. Criar Primeiro Post (Ativar Corrente)
- [ ] Preencher formulário de destaque normalmente
- [ ] Criar post
- [ ] Post deve ser criado com sucesso
- [ ] Notificação: "🎉 Corrente iniciada com sucesso!"
- [ ] UI deve restaurar (botão "Criar Corrente" volta)
- [ ] Tipo de destaque deve ser liberado

#### 1.6. Verificar Post com Badge de Corrente
- [ ] Ir para aba "Início"
- [ ] Localizar o post criado
- [ ] Verificar se aparece badge laranja "[Nome da Corrente] 🔗" ao lado do tipo
- [ ] Badge deve ter efeito hover

### 2. PARTICIPAÇÃO EM CORRENTE

#### 2.1. Visualizar Corrente
- [ ] Clicar no badge da corrente no post
- [ ] Modal "🔗 [Nome da Corrente]" deve abrir
- [ ] Verificar se mostra: Nome, Descrição, Tipo, Posts, Participantes

#### 2.2. Participar da Corrente
- [ ] Clicar em "Participar da Corrente"
- [ ] Modal deve fechar
- [ ] Aba "Destacar" deve abrir automaticamente
- [ ] Nome da corrente + "Cancelar" deve aparecer
- [ ] Tipo de destaque deve estar fixado
- [ ] Tooltip deve funcionar

#### 2.3. Cancelar Participação
- [ ] Clicar em "Cancelar"
- [ ] Confirmação deve aparecer
- [ ] Confirmar cancelamento
- [ ] UI deve restaurar (botão "Criar Corrente" volta)
- [ ] Notificação: "✅ Participação cancelada"

#### 2.4. Participar e Criar Post
- [ ] Repetir passos 2.1 e 2.2
- [ ] Criar post normalmente
- [ ] Notificação: "🎉 Você participou da corrente com sucesso!"
- [ ] UI deve restaurar
- [ ] Post deve aparecer com badge da corrente

### 3. CANCELAMENTO DE CORRENTE

#### 3.1. Cancelar Corrente Pendente (Sem Posts)
- [ ] Criar nova corrente
- [ ] Clicar em "Cancelar Corrente"
- [ ] Confirmação deve aparecer
- [ ] Confirmar cancelamento
- [ ] Corrente deve ser deletada
- [ ] UI deve restaurar
- [ ] Notificação de sucesso

#### 3.2. Tentar Cancelar Corrente Ativa (Com Posts)
- [ ] Criar corrente e fazer primeiro post
- [ ] Tentar cancelar → Não deve ser possível (botão não aparece mais)

### 4. GAMIFICAÇÃO

#### 4.1. Pontos por Criar Corrente
- [ ] Verificar pontos antes de criar
- [ ] Criar corrente
- [ ] Verificar pontos depois
- [ ] Deve ter +25 pontos

#### 4.2. Badge "Iniciador" (1ª Corrente)
- [ ] Criar primeira corrente
- [ ] Verificar notificações
- [ ] Badge "Iniciador 🔗" deve aparecer
- [ ] +50 pontos bônus devem ser creditados

#### 4.3. Pontos por Participar
- [ ] Verificar pontos antes de participar
- [ ] Participar de corrente
- [ ] Verificar pontos depois
- [ ] Deve ter +15 pontos

#### 4.4. Badge "Elo" (1ª Participação)
- [ ] Participar da primeira corrente
- [ ] Verificar notificações
- [ ] Badge "Elo 🔗" deve aparecer
- [ ] +50 pontos bônus devem ser creditados

### 5. RASTREAMENTO E DADOS

#### 5.1. Verificar Tabela chains
```sql
SELECT * FROM chains ORDER BY created_at DESC LIMIT 5;
```
- [ ] Correntes criadas devem aparecer
- [ ] `status` deve ser 'pending' ou 'active'
- [ ] `start_date` deve estar preenchido para correntes ativas

#### 5.2. Verificar Tabela chain_posts
```sql
SELECT * FROM chain_posts ORDER BY created_at DESC LIMIT 5;
```
- [ ] Posts vinculados devem aparecer
- [ ] `parent_post_author_id` deve estar correto
- [ ] Primeiro post deve ter `parent_post_author_id = NULL`

#### 5.3. Verificar Pontuação
```sql
SELECT * FROM points_history 
WHERE action_type IN ('chain_created', 'chain_participated') 
ORDER BY created_at DESC LIMIT 10;
```
- [ ] Registros devem aparecer
- [ ] `chain_created` = 25 pontos
- [ ] `chain_participated` = 15 pontos

#### 5.4. Verificar Badges
```sql
SELECT ub.*, b.name, b.points_required 
FROM user_badges ub 
JOIN badges b ON ub.badge_id = b.id 
WHERE b.category = 'correntes' 
ORDER BY ub.earned_at DESC;
```
- [ ] Badges concedidos devem aparecer
- [ ] Pontos bônus devem ter sido creditados

### 6. FUNÇÕES SQL

#### 6.1. get_chain_info
```sql
SELECT * FROM get_chain_info('[chain_id]');
```
- [ ] Deve retornar JSON com informações completas
- [ ] `posts_count` deve estar correto
- [ ] `participants_count` deve estar correto

#### 6.2. get_chain_tree
```sql
SELECT * FROM get_chain_tree('[chain_id]');
```
- [ ] Deve retornar array JSON com árvore
- [ ] Profundidade (`depth`) deve estar correta
- [ ] Hierarquia deve estar correta

#### 6.3. count_user_created_chains
```sql
SELECT count_user_created_chains('[user_id]');
```
- [ ] Deve retornar número correto de correntes criadas

#### 6.4. count_user_participated_chains
```sql
SELECT count_user_participated_chains('[user_id]');
```
- [ ] Deve retornar número correto de participações

### 7. SEGURANÇA (RLS)

#### 7.1. Permissões de Leitura
- [ ] Usuário autenticado pode ver correntes `active`
- [ ] Usuário autenticado pode ver correntes `closed`
- [ ] Usuário NÃO pode ver correntes `pending` de outros

#### 7.2. Permissões de Escrita
- [ ] Apenas criador pode cancelar corrente
- [ ] Apenas criador pode atualizar corrente
- [ ] Qualquer usuário autenticado pode participar

### 8. INTERFACE E UX

#### 8.1. Responsividade
- [ ] Modal de criação responsivo
- [ ] Modal de visualização responsivo
- [ ] Badge nos posts não quebra layout
- [ ] Botões responsivos

#### 8.2. Feedback Visual
- [ ] Efeitos hover funcionam
- [ ] Transições suaves
- [ ] Notificações aparecem e desaparecem
- [ ] Loading states (se aplicável)

#### 8.3. Acessibilidade
- [ ] Tooltips funcionam corretamente
- [ ] Modais podem ser fechados com ESC (se implementado)
- [ ] Foco do teclado funciona
- [ ] Contraste de cores adequado

---

## 🐛 BUGS CONHECIDOS

*Nenhum bug conhecido no momento.*

---

## 📝 NOTAS DE TESTE

### Ambiente de Teste:
- [ ] Navegador: Chrome/Firefox/Safari
- [ ] Dispositivo: Desktop/Mobile
- [ ] Usuário de teste criado

### Dados de Teste:
- [ ] Pelo menos 2 usuários para testar participação
- [ ] Pelo menos 3 correntes criadas
- [ ] Pelo menos 5 posts vinculados

---

## ✅ CRITÉRIOS DE ACEITAÇÃO

- [ ] Todas as funcionalidades básicas funcionam
- [ ] Gamificação funciona corretamente
- [ ] Rastreamento de dados está correto
- [ ] Segurança (RLS) está configurada
- [ ] Interface é intuitiva e responsiva
- [ ] Sem erros no console do navegador
- [ ] Sem erros nos logs do Supabase

---

## 🎯 PRÓXIMOS PASSOS (FUTURO)

1. Implementar função `close_chain` (fechar corrente manualmente)
2. Adicionar página de visualização de todas as correntes
3. Adicionar ranking de correntes mais virais
4. Adicionar notificações quando alguém participa da sua corrente
5. Adicionar estatísticas de correntes no perfil

---

**Documento criado em:** 04/12/2025  
**Última atualização:** 04/12/2025  
**Responsável:** Sistema Manus AI
