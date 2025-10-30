# Atualização da Constraint `check_default_feed_values`

## Problema

Ao tentar salvar uma comunidade como feed padrão, o banco de dados retorna o erro:

```
new row for relation "profiles" violates check constraint "check_default_feed_values"
```

Isso acontece porque a constraint atual só aceita os valores `'recommended'` ou `'following'`, mas agora precisamos aceitar também valores no formato `'community-{uuid}'`.

## Solução

Execute o script SQL `update_default_feed_constraint.sql` no Supabase SQL Editor.

### Passo a passo:

1. Acesse o **Supabase Dashboard**: https://app.supabase.com
2. Selecione o projeto **HoloSpot**
3. Vá em **SQL Editor** no menu lateral
4. Clique em **New Query**
5. Cole o conteúdo do arquivo `update_default_feed_constraint.sql`
6. Clique em **Run** (ou pressione Ctrl+Enter)

### O que o script faz:

1. **Remove a constraint antiga** que só aceitava `'recommended'` e `'following'`
2. **Cria uma nova constraint** que aceita:
   - `'recommended'` (feed de recomendados)
   - `'following'` (feed de seguindo)
   - `'community-{uuid}'` (feed de qualquer comunidade)

### Verificação:

Após executar o script, você deve ver uma mensagem de sucesso e a constraint atualizada:

```
conname                      | pg_get_constraintdef
-----------------------------+--------------------------------------------------
check_default_feed_values    | CHECK ((default_feed = ANY (ARRAY['recommended'::text, 'following'::text])) OR (default_feed ~~ 'community-%'::text))
```

### Teste:

Após a atualização, tente salvar novamente uma comunidade como feed padrão no modal de Configurações. Agora deve funcionar sem erros!

## Arquivos relacionados:

- `update_default_feed_constraint.sql` - Script SQL para executar no Supabase
- `index.html` (linhas 6207-6253) - Código que carrega comunidades no dropdown
- `index.html` (linhas 16157-16201) - Código que carrega feed de comunidade na inicialização
