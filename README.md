# 🌟 HoloSpot

Sistema de rede social com gamificação e notificações inteligentes.

## 📊 Status Atual

**Versão:** v4.1-stable + Fase 5 (Notificações)  
**Status:** ✅ Produção  
**Última atualização:** 2025-09-16

## 🚀 Funcionalidades

### 🏆 **Gamificação (Fase 4)**
- Sistema completo de pontos e níveis
- Badges automáticos com bônus por raridade
- Streak system com multiplicadores
- Progressão visual e conquistas

### 🔔 **Notificações (Fase 5)**
- Sistema anti-spam inteligente
- Notificações em tempo real
- Mensagens padronizadas
- Suporte a holofotes e interações

### 📱 **Core Features**
- Posts e holofotes (@menções)
- Sistema de reações e comentários
- Feedbacks e follows
- Interface responsiva
- Autenticação segura

## 📁 Estrutura do Projeto

```
holospot/
├── index.html              # Frontend principal
├── sql/                    # Scripts SQL organizados
│   ├── functions/          # Funções do banco
│   ├── triggers/           # Triggers automáticos
│   ├── migrations/         # Migrações e atualizações
│   ├── tests/              # Testes e verificações
│   └── backup/             # Scripts de backup
├── docs/                   # Documentação
│   ├── ESTADO_ATUAL.md     # Status atual do sistema
│   ├── CHANGELOG.md        # Histórico de mudanças
│   └── ESTRUTURA_TABELAS_DEFINITIVA.md
└── README.md               # Este arquivo
```

## 🔧 Configuração

### **Banco de Dados**
- PostgreSQL via Supabase
- Triggers automáticos para gamificação
- Sistema de notificações em tempo real

### **Frontend**
- HTML5 + JavaScript vanilla
- CSS responsivo
- Integração com Supabase

## 📋 Comandos Úteis

### **Verificar Sistema**
```sql
-- No Supabase SQL Editor
\i sql/tests/system_verification.sql
```

### **Backup Completo**
```sql
-- No Supabase SQL Editor  
\i sql/backup/full_backup.sql
```

### **Aplicar Migrações**
```sql
-- Executar em ordem numérica
\i sql/migrations/001_fase5_sistema_notificacoes.sql
```

## 📊 Métricas

Para verificar métricas atuais, consulte:
- `docs/ESTADO_ATUAL.md` - Status detalhado
- `sql/tests/system_verification.sql` - Verificação completa

## 🔄 Desenvolvimento

### **Workflow**
1. Consultar `docs/ESTADO_ATUAL.md`
2. Criar/modificar arquivos SQL em `sql/`
3. Testar com `sql/tests/system_verification.sql`
4. Atualizar documentação
5. Commit com mensagem descritiva

### **Branches**
- `main` - Código de produção
- `develop` - Desenvolvimento ativo
- `feature/*` - Funcionalidades específicas

## 🚨 Importante

### **Antes de Modificar:**
1. ✅ Consulte `docs/ESTADO_ATUAL.md`
2. ✅ Verifique `docs/ESTRUTURA_TABELAS_DEFINITIVA.md`
3. ✅ Execute testes de verificação
4. ✅ Faça backup se necessário

### **Estrutura das Tabelas:**
- **feedbacks:** `author_id` = autor do POST, `mentioned_user_id` = quem deu feedback
- **reactions:** `user_id` = quem reagiu
- **comments:** `user_id` = quem comentou
- **follows:** `follower_id` = quem segue, `following_id` = quem é seguido
- **posts:** `mentioned_user_id` = quem foi mencionado (holofote)

## 📞 Suporte

Para problemas ou dúvidas:
1. Consulte `docs/CHANGELOG.md` para mudanças recentes
2. Execute `sql/tests/system_verification.sql` para diagnóstico
3. Verifique logs do Supabase Dashboard

## 📄 Licença

Projeto privado - Todos os direitos reservados.

---

**🌟 HoloSpot - Conectando pessoas através de gamificação inteligente**

