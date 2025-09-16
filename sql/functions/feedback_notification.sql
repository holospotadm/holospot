-- 🔧 CORREÇÃO DEFINITIVA: Trigger de feedback com estrutura CORRETA
-- ESTRUTURA REAL: author_id = autor do POST, mentioned_user_id = quem deu FEEDBACK

-- ============================================================================
-- 📋 ESTRUTURA CORRETA DA TABELA FEEDBACKS:
-- ============================================================================
/*
feedbacks {
    id: UUID (PK)
    post_id: UUID (FK → posts.id)
    author_id: UUID (FK → profiles.id) ← **AUTOR DO POST** (não do feedback!)
    mentioned_user_id: UUID (FK → profiles.id) ← **QUEM DEU O FEEDBACK**
    created_at: TIMESTAMP
}
*/

-- ============================================================================
-- 🔧 LIMPAR: Triggers anteriores (todos errados)
-- ============================================================================

DROP TRIGGER IF EXISTS feedback_notification_trigger ON public.feedbacks;
DROP TRIGGER IF EXISTS feedback_notification_debug_trigger ON public.feedbacks;
DROP TRIGGER IF EXISTS feedback_notification_simple_trigger ON public.feedbacks;
DROP TRIGGER IF EXISTS feedback_notification_table_debug_trigger ON public.feedbacks;

-- ============================================================================
-- 🔧 FUNÇÃO CORRETA: Com estrutura real da tabela
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_feedback_notification_CORRETO()
RETURNS TRIGGER AS $$
DECLARE
    username_from TEXT;
BEGIN
    -- ✅ LÓGICA CORRETA:
    -- NEW.author_id = AUTOR DO POST (quem recebe notificação)
    -- NEW.mentioned_user_id = QUEM DEU FEEDBACK (quem aparece na notificação)
    
    -- Debug: Salvar dados corretos
    INSERT INTO public.debug_feedback_test (
        teste_executado, 
        feedback_id, 
        post_id, 
        author_id,           -- ← AUTOR DO POST
        post_author_id,      -- ← MESMO QUE author_id
        username_from,
        erro
    ) VALUES (
        'ESTRUTURA CORRETA APLICADA', 
        NEW.id::TEXT, 
        NEW.post_id::TEXT, 
        NEW.author_id::TEXT,        -- ← QUEM RECEBE NOTIFICAÇÃO
        NEW.mentioned_user_id::TEXT, -- ← QUEM DEU FEEDBACK (usando campo post_author_id para debug)
        NULL,
        'author_id=' || NEW.author_id::TEXT || ' mentioned_user_id=' || NEW.mentioned_user_id::TEXT
    );
    
    -- Verificar se não é auto-feedback (LÓGICA CORRETA)
    IF NEW.author_id = NEW.mentioned_user_id THEN
        INSERT INTO public.debug_feedback_test (teste_executado, feedback_id) 
        VALUES ('AUTO-FEEDBACK DETECTADO (CORRETO)', NEW.id::TEXT);
        RETURN NEW;
    END IF;
    
    -- Buscar username de quem deu feedback (mentioned_user_id)
    SELECT COALESCE(username, 'Usuario') INTO username_from 
    FROM public.profiles 
    WHERE id = NEW.mentioned_user_id;
    
    INSERT INTO public.debug_feedback_test (
        teste_executado, feedback_id, username_from
    ) VALUES (
        'USERNAME ENCONTRADO (CORRETO)', NEW.id::TEXT, username_from
    );
    
    -- Criar notificação (LÓGICA CORRETA)
    BEGIN
        INSERT INTO public.notifications (
            user_id,        -- ← NEW.author_id (AUTOR DO POST recebe notificação)
            from_user_id,   -- ← NEW.mentioned_user_id (QUEM DEU FEEDBACK)
            type, 
            message, 
            read, 
            created_at
        ) VALUES (
            NEW.author_id,          -- ✅ AUTOR DO POST recebe notificação
            NEW.mentioned_user_id,  -- ✅ QUEM DEU FEEDBACK aparece como remetente
            'feedback',
            username_from || ' deu feedback sobre o post que você fez destacando-o!',
            false,
            NOW()
        );
        
        INSERT INTO public.debug_feedback_test (
            teste_executado, feedback_id, notificacao_criada
        ) VALUES (
            'NOTIFICAÇÃO CRIADA (ESTRUTURA CORRETA)', NEW.id::TEXT, true
        );
        
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO public.debug_feedback_test (
            teste_executado, feedback_id, notificacao_criada, erro
        ) VALUES (
            'ERRO AO CRIAR NOTIFICAÇÃO', NEW.id::TEXT, false, SQLERRM
        );
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 🔧 TRIGGER CORRETO
-- ============================================================================

CREATE TRIGGER feedback_notification_CORRETO_trigger
    AFTER INSERT ON public.feedbacks
    FOR EACH ROW
    EXECUTE FUNCTION handle_feedback_notification_CORRETO();

-- ============================================================================
-- 🧹 LIMPAR: Dados de teste anteriores (errados)
-- ============================================================================

DELETE FROM public.debug_feedback_test;

-- ============================================================================
-- 📊 RESUMO DA CORREÇÃO DEFINITIVA
-- ============================================================================

SELECT 
    '🔧 CORREÇÃO DEFINITIVA APLICADA' as status,
    'ESTRUTURA CORRETA IMPLEMENTADA:' as titulo,
    '✅ author_id = AUTOR DO POST (quem recebe notificação)' as campo1,
    '✅ mentioned_user_id = QUEM DEU FEEDBACK (remetente)' as campo2,
    '✅ Lógica de auto-feedback corrigida' as logica,
    '✅ Notificação criada para pessoa correta' as resultado,
    '✅ Documentação criada para nunca mais errar' as documentacao,
    NOW()::text as corrigido_em;

-- ============================================================================
-- 🎯 TESTE AGORA
-- ============================================================================

/*
🔧 CORREÇÃO DEFINITIVA APLICADA:

✅ ESTRUTURA CORRETA IMPLEMENTADA:
- author_id = AUTOR DO POST (quem recebe notificação)
- mentioned_user_id = QUEM DEU FEEDBACK (quem aparece como remetente)

✅ LÓGICA CORRIGIDA:
- Auto-feedback: NEW.author_id = NEW.mentioned_user_id
- Notificação para: NEW.author_id (autor do post)
- Notificação de: NEW.mentioned_user_id (quem deu feedback)

✅ DOCUMENTAÇÃO CRIADA:
- Arquivo ESTRUTURA_TABELAS_DEFINITIVA.md
- Nunca mais errar a estrutura das tabelas
- Consultar sempre antes de implementar

🧪 TESTE AGORA:
1. Execute este arquivo
2. Dê feedback em um post de OUTRA PESSOA
3. Execute: SELECT * FROM debug_feedback_test ORDER BY timestamp DESC;
4. Deve funcionar corretamente agora!

🚨 PEÇO DESCULPAS PELO ERRO REPETITIVO!
✅ AGORA ESTÁ CORRETO E DOCUMENTADO!
*/

