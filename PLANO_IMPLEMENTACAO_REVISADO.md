# Plano de Implementação REVISADO - 3 Novas Funcionalidades HoloSpot

## 🎯 Visão Geral

Este documento detalha o planejamento técnico **REVISADO** para implementação de 3 novas funcionalidades no HoloSpot, seguindo a arquitetura de **cards na aba Perfil com modais**:

1. **💬 Chat/Mensagens Privadas** - Card + Modal
2. **⚙️ Configurações de Perfil** - Card + Modal  
3. **🔍 Filtros de Feed** - Botões na aba Início

---

## 📐 Arquitetura Revisada

### Padrão de Design Adotado

Seguindo o padrão já existente no HoloSpot:
- ✅ **Cards clicáveis** na aba Perfil (como "Posts Criados", "Holofotes Recebidos")
- ✅ **Modais overlay** para conteúdo detalhado (como `impactModal`, `achievementsModal`)
- ✅ **Grid responsivo** que se adapta a mobile (6 colunas → 1 coluna)
- ✅ **Consistência visual** com cards existentes

### Vantagens desta Abordagem

1. **UX Consistente** - Usuário já conhece o padrão de interação
2. **Menos Navegação** - Tudo acessível da aba Perfil
3. **Mobile-Friendly** - Modais funcionam melhor que múltiplas abas em mobile
4. **Organização** - Perfil como hub central do usuário

---

## 1️⃣ Chat/Mensagens Privadas (Card + Modal)

### 1.1 Localização

**Card na aba Perfil**, posicionado após os cards de métricas existentes, antes do botão "Ver Impacto Detalhado".

### 1.2 Schema do Banco de Dados

#### Tabela: `conversations`

```sql
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now(),
    last_message_at TIMESTAMPTZ DEFAULT now(),
    last_message_preview TEXT,
    last_message_from UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at 
ON public.conversations (last_message_at DESC);

COMMENT ON TABLE public.conversations IS 
'Conversas entre usuários. Preparado para grupos futuros.';
```

#### Tabela: `conversation_participants`

```sql
CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT now(),
    last_read_at TIMESTAMPTZ DEFAULT now(),
    unread_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT false,
    
    CONSTRAINT unique_conversation_participant UNIQUE (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id 
ON public.conversation_participants (user_id);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id 
ON public.conversation_participants (conversation_id);

CREATE INDEX IF NOT EXISTS idx_conversation_participants_unread 
ON public.conversation_participants (user_id, unread_count) 
WHERE unread_count > 0;

COMMENT ON TABLE public.conversation_participants IS 
'Relaciona usuários com conversas. Armazena estado de leitura.';
```

#### Tabela: `messages`

```sql
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_url TEXT,
    message_type VARCHAR(20) DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT now(),
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id 
ON public.messages (conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_sender_id 
ON public.messages (sender_id);

CREATE INDEX IF NOT EXISTS idx_messages_created_at 
ON public.messages (created_at DESC);

COMMENT ON TABLE public.messages IS 
'Mensagens trocadas nas conversas.';
```

### 1.3 Funções SQL

```sql
-- Buscar ou criar conversa entre dois usuários
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
    p_user1_id UUID,
    p_user2_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Buscar conversa existente
    SELECT c.id INTO v_conversation_id
    FROM conversations c
    INNER JOIN conversation_participants cp1 ON cp1.conversation_id = c.id
    INNER JOIN conversation_participants cp2 ON cp2.conversation_id = c.id
    WHERE cp1.user_id = p_user1_id
      AND cp2.user_id = p_user2_id
      AND (SELECT COUNT(*) FROM conversation_participants WHERE conversation_id = c.id) = 2
    LIMIT 1;
    
    -- Se não existe, criar
    IF v_conversation_id IS NULL THEN
        INSERT INTO conversations DEFAULT VALUES
        RETURNING id INTO v_conversation_id;
        
        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES 
            (v_conversation_id, p_user1_id),
            (v_conversation_id, p_user2_id);
    END IF;
    
    RETURN v_conversation_id;
END;
$$;

-- Enviar mensagem
CREATE OR REPLACE FUNCTION public.send_message(
    p_conversation_id UUID,
    p_sender_id UUID,
    p_content TEXT,
    p_media_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_message_id UUID;
BEGIN
    INSERT INTO messages (conversation_id, sender_id, content, media_url)
    VALUES (p_conversation_id, p_sender_id, p_content, p_media_url)
    RETURNING id INTO v_message_id;
    
    UPDATE conversations
    SET 
        last_message_at = now(),
        last_message_preview = LEFT(p_content, 100),
        last_message_from = p_sender_id
    WHERE id = p_conversation_id;
    
    UPDATE conversation_participants
    SET unread_count = unread_count + 1
    WHERE conversation_id = p_conversation_id
      AND user_id != p_sender_id;
    
    RETURN v_message_id;
END;
$$;

-- Marcar como lida
CREATE OR REPLACE FUNCTION public.mark_conversation_as_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE conversation_participants
    SET 
        last_read_at = now(),
        unread_count = 0
    WHERE conversation_id = p_conversation_id
      AND user_id = p_user_id;
END;
$$;

-- Contar mensagens não lidas do usuário
CREATE OR REPLACE FUNCTION public.get_total_unread_messages(
    p_user_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COALESCE(SUM(unread_count), 0) INTO v_total
    FROM conversation_participants
    WHERE user_id = p_user_id;
    
    RETURN v_total;
END;
$$;
```

### 1.4 Triggers

```sql
CREATE OR REPLACE FUNCTION handle_new_message_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_participant RECORD;
    v_sender_name TEXT;
BEGIN
    SELECT name INTO v_sender_name
    FROM profiles
    WHERE id = NEW.sender_id;
    
    FOR v_participant IN 
        SELECT user_id 
        FROM conversation_participants 
        WHERE conversation_id = NEW.conversation_id 
          AND user_id != NEW.sender_id
    LOOP
        INSERT INTO notifications (user_id, from_user_id, type, message, priority)
        VALUES (
            v_participant.user_id,
            NEW.sender_id,
            'new_message',
            v_sender_name || ' enviou uma mensagem',
            2
        );
    END LOOP;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_new_message_notification
    AFTER INSERT ON messages
    FOR EACH ROW
    WHEN (NEW.message_type = 'text')
    EXECUTE FUNCTION handle_new_message_notification();
```

### 1.5 RLS Policies

```sql
-- Conversas
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = conversations.id AND user_id = auth.uid()
    )
);

-- Participantes
CREATE POLICY "Users can view participants of their conversations"
ON conversation_participants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants cp2
        WHERE cp2.conversation_id = conversation_participants.conversation_id
          AND cp2.user_id = auth.uid()
    )
);

-- Mensagens - SELECT
CREATE POLICY "Users can view messages from their conversations"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
    )
);

-- Mensagens - INSERT
CREATE POLICY "Users can send messages to their conversations"
ON messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM conversation_participants
        WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
    )
);

-- Habilitar RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
```

### 1.6 Card na Aba Perfil

**Adicionar após a segunda `stats-grid` (linha ~2795), antes do botão "Ver Impacto Detalhado":**

```html
<!-- Card de Mensagens -->
<div class="messages-card-container" style="margin-top: 2rem; margin-bottom: 2rem;">
    <div class="stat-card messages-card" onclick="openMessagesModal()" style="
        cursor: pointer; 
        transition: transform 0.2s ease, box-shadow 0.2s ease; 
        box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
        border-radius: 12px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        position: relative;
        padding: 1.5rem;
    " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 4px 16px rgba(102, 126, 234, 0.3)';" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 2px 8px rgba(0,0,0,0.1)';">
        <div style="display: flex; align-items: center; justify-content: space-between;">
            <div>
                <div style="font-size: 2.5rem; margin-bottom: 0.5rem;">💬</div>
                <div style="font-size: 1.2rem; font-weight: 600; margin-bottom: 0.25rem;">Mensagens</div>
                <div style="font-size: 0.9rem; opacity: 0.9;">Converse com outros usuários</div>
            </div>
            <div id="unreadMessagesCount" style="
                background: #ff3b30;
                color: white;
                border-radius: 50%;
                width: 32px;
                height: 32px;
                display: none;
                align-items: center;
                justify-content: center;
                font-weight: bold;
                font-size: 0.9rem;
            ">0</div>
        </div>
    </div>
</div>
```

### 1.7 Modal de Mensagens

**Adicionar após os modais existentes (linha ~14020):**

```html
<!-- Modal de Mensagens -->
<div id="messagesModal" class="modal-overlay" style="display: none;">
    <div class="modal-container" style="max-width: 1000px; height: 80vh; display: flex; flex-direction: column;" onclick="event.stopPropagation()">
        <div class="modal-header">
            <h2>💬 Mensagens</h2>
            <button class="close-btn" onclick="closeMessagesModal()">&times;</button>
        </div>
        <div class="modal-body" style="flex: 1; display: flex; overflow: hidden; padding: 0;">
            <!-- Lista de Conversas (Sidebar) -->
            <div class="conversations-sidebar" id="conversationsSidebar" style="
                width: 350px;
                border-right: 1px solid #ddd;
                overflow-y: auto;
                background: #f8f9fa;
            ">
                <div style="padding: 1rem; border-bottom: 1px solid #ddd; background: white;">
                    <input 
                        type="text" 
                        id="searchConversations" 
                        placeholder="🔍 Buscar conversas..."
                        style="
                            width: 100%;
                            padding: 0.75rem;
                            border: 1px solid #ddd;
                            border-radius: 20px;
                            font-size: 0.9rem;
                        "
                    >
                </div>
                <div id="conversationsList">
                    <!-- Conversas carregadas aqui -->
                </div>
            </div>
            
            <!-- Área de Chat -->
            <div class="chat-area" id="chatArea" style="flex: 1; display: flex; flex-direction: column;">
                <div class="chat-placeholder" style="
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    color: #666;
                    padding: 2rem;
                ">
                    <div style="font-size: 64px; margin-bottom: 1rem;">💬</div>
                    <h3 style="margin-bottom: 0.5rem;">Selecione uma conversa</h3>
                    <p>Escolha uma conversa existente ou inicie uma nova</p>
                </div>
            </div>
        </div>
    </div>
</div>
```

### 1.8 JavaScript - Funções Principais

```javascript
// Abrir modal de mensagens
async function openMessagesModal() {
    document.getElementById('messagesModal').style.display = 'flex';
    await loadConversations();
}

// Fechar modal
function closeMessagesModal() {
    document.getElementById('messagesModal').style.display = 'none';
}

// Carregar conversas
async function loadConversations() {
    const { data: participants, error } = await supabase
        .from('conversation_participants')
        .select(`
            conversation_id,
            unread_count,
            conversations:conversation_id (
                id,
                last_message_at,
                last_message_preview,
                last_message_from
            )
        `)
        .eq('user_id', currentUser.id)
        .order('conversations.last_message_at', { ascending: false });
    
    if (error) {
        console.error('Erro ao carregar conversas:', error);
        return;
    }
    
    // Buscar dados dos outros participantes
    const conversationIds = participants.map(p => p.conversation_id);
    
    const { data: allParticipants, error: participantsError } = await supabase
        .from('conversation_participants')
        .select(`
            conversation_id,
            user_id,
            profiles:user_id (
                id,
                name,
                username,
                avatar_url
            )
        `)
        .in('conversation_id', conversationIds)
        .neq('user_id', currentUser.id);
    
    if (participantsError) {
        console.error('Erro ao carregar participantes:', participantsError);
        return;
    }
    
    renderConversationsList(participants, allParticipants);
}

// Renderizar lista de conversas
function renderConversationsList(participants, allParticipants) {
    const listDiv = document.getElementById('conversationsList');
    
    if (participants.length === 0) {
        listDiv.innerHTML = `
            <div style="padding: 2rem; text-align: center; color: #666;">
                <div style="font-size: 48px; margin-bottom: 1rem;">💬</div>
                <p>Nenhuma conversa ainda</p>
                <p style="font-size: 0.9rem; margin-top: 0.5rem;">
                    Vá para o perfil de alguém e clique em "Enviar Mensagem"
                </p>
            </div>
        `;
        return;
    }
    
    let html = '';
    
    participants.forEach(p => {
        const conversation = p.conversations;
        const otherParticipant = allParticipants.find(ap => ap.conversation_id === p.conversation_id);
        
        if (!otherParticipant) return;
        
        const profile = otherParticipant.profiles;
        const isUnread = p.unread_count > 0;
        
        html += `
            <div class="conversation-item ${isUnread ? 'unread' : ''}" onclick="openConversation('${conversation.id}')" style="
                padding: 1rem;
                border-bottom: 1px solid #eee;
                cursor: pointer;
                transition: background 0.2s;
                display: flex;
                gap: 12px;
                align-items: center;
                ${isUnread ? 'background: #fff3cd;' : ''}
            " onmouseover="this.style.background='#e9ecef'" onmouseout="this.style.background='${isUnread ? '#fff3cd' : 'transparent'}'">
                <img src="${profile.avatar_url || ''}" 
                     style="width: 48px; height: 48px; border-radius: 50%; object-fit: cover; background: #ddd;"
                     onerror="this.style.display='none'">
                <div style="flex: 1; min-width: 0;">
                    <div style="font-weight: ${isUnread ? 'bold' : '600'}; margin-bottom: 4px;">
                        ${profile.name || '@' + (profile.username || 'usuario')}
                    </div>
                    <div style="
                        font-size: 0.85rem; 
                        color: #666; 
                        white-space: nowrap; 
                        overflow: hidden; 
                        text-overflow: ellipsis;
                        ${isUnread ? 'font-weight: 600;' : ''}
                    ">
                        ${conversation.last_message_preview || 'Nenhuma mensagem ainda'}
                    </div>
                </div>
                ${isUnread ? `
                    <div style="
                        background: #ff3b30;
                        color: white;
                        border-radius: 50%;
                        width: 24px;
                        height: 24px;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 0.75rem;
                        font-weight: bold;
                    ">${p.unread_count}</div>
                ` : ''}
            </div>
        `;
    });
    
    listDiv.innerHTML = html;
}

// Abrir conversa específica
async function openConversation(conversationId) {
    // Marcar como lida
    await supabase.rpc('mark_conversation_as_read', {
        p_conversation_id: conversationId,
        p_user_id: currentUser.id
    });
    
    // Carregar mensagens
    const { data: messages, error } = await supabase
        .from('messages')
        .select(`
            id,
            content,
            media_url,
            created_at,
            is_edited,
            sender:sender_id (
                id,
                name,
                avatar_url
            )
        `)
        .eq('conversation_id', conversationId)
        .eq('is_deleted', false)
        .order('created_at', { ascending: true });
    
    if (error) {
        console.error('Erro ao carregar mensagens:', error);
        return;
    }
    
    renderChatArea(conversationId, messages);
    
    // Atualizar contador de não lidas
    updateUnreadCount();
}

// Renderizar área de chat
function renderChatArea(conversationId, messages) {
    const chatArea = document.getElementById('chatArea');
    
    let html = `
        <div class="chat-header" style="
            padding: 1rem;
            border-bottom: 1px solid #ddd;
            background: white;
        ">
            <h3 style="margin: 0;">Chat</h3>
        </div>
        <div class="chat-messages" id="chatMessages" style="
            flex: 1;
            overflow-y: auto;
            padding: 1rem;
            background: #f8f9fa;
        ">
    `;
    
    messages.forEach(msg => {
        const isSent = msg.sender.id === currentUser.id;
        html += `
            <div class="message ${isSent ? 'sent' : 'received'}" style="
                margin-bottom: 1rem;
                display: flex;
                gap: 8px;
                ${isSent ? 'flex-direction: row-reverse;' : ''}
            ">
                <img src="${msg.sender.avatar_url || ''}" 
                     style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover; background: #ddd;"
                     onerror="this.style.display='none'">
                <div class="message-bubble" style="
                    max-width: 70%;
                    padding: 0.75rem 1rem;
                    border-radius: 18px;
                    background: ${isSent ? '#667eea' : 'white'};
                    color: ${isSent ? 'white' : '#333'};
                    box-shadow: 0 1px 2px rgba(0,0,0,0.1);
                ">
                    <div>${msg.content}</div>
                    <div style="
                        font-size: 0.7rem;
                        opacity: 0.7;
                        margin-top: 4px;
                    ">${formatTime(msg.created_at)}</div>
                </div>
            </div>
        `;
    });
    
    html += `
        </div>
        <div class="chat-input-area" style="
            padding: 1rem;
            border-top: 1px solid #ddd;
            background: white;
            display: flex;
            gap: 8px;
        ">
            <input 
                type="text" 
                id="messageInput" 
                placeholder="Digite sua mensagem..."
                style="
                    flex: 1;
                    padding: 0.75rem 1rem;
                    border: 1px solid #ddd;
                    border-radius: 20px;
                    font-size: 0.9rem;
                "
                onkeypress="if(event.key==='Enter') sendMessage('${conversationId}')"
            >
            <button onclick="sendMessage('${conversationId}')" style="
                padding: 0.75rem 1.5rem;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 20px;
                cursor: pointer;
                font-weight: 600;
                transition: background 0.2s;
            " onmouseover="this.style.background='#5568d3'" onmouseout="this.style.background='#667eea'">
                Enviar
            </button>
        </div>
    `;
    
    chatArea.innerHTML = html;
    
    // Scroll para última mensagem
    setTimeout(() => {
        const messagesDiv = document.getElementById('chatMessages');
        messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }, 100);
}

// Enviar mensagem
async function sendMessage(conversationId) {
    const input = document.getElementById('messageInput');
    const content = input.value.trim();
    
    if (!content) return;
    
    const { error } = await supabase.rpc('send_message', {
        p_conversation_id: conversationId,
        p_sender_id: currentUser.id,
        p_content: content
    });
    
    if (error) {
        console.error('Erro ao enviar mensagem:', error);
        showToast('Erro ao enviar mensagem');
        return;
    }
    
    input.value = '';
    openConversation(conversationId);
}

// Atualizar contador de não lidas
async function updateUnreadCount() {
    const { data: total, error } = await supabase.rpc('get_total_unread_messages', {
        p_user_id: currentUser.id
    });
    
    if (error) {
        console.error('Erro ao contar não lidas:', error);
        return;
    }
    
    const badge = document.getElementById('unreadMessagesCount');
    if (total > 0) {
        badge.textContent = total > 99 ? '99+' : total;
        badge.style.display = 'flex';
    } else {
        badge.style.display = 'none';
    }
}

// Iniciar conversa com usuário (chamado de outros perfis)
async function startConversationWithUser(userId) {
    const { data: conversationId, error } = await supabase.rpc('get_or_create_conversation', {
        p_user1_id: currentUser.id,
        p_user2_id: userId
    });
    
    if (error) {
        console.error('Erro ao criar conversa:', error);
        return;
    }
    
    openMessagesModal();
    setTimeout(() => openConversation(conversationId), 500);
}

// Formatar hora
function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}

// Realtime - escutar novas mensagens
function setupMessagesRealtime() {
    supabase
        .channel('messages')
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'messages'
        }, (payload) => {
            // Atualizar contador
            updateUnreadCount();
            
            // Se o modal está aberto e é a conversa atual, recarregar
            const modal = document.getElementById('messagesModal');
            if (modal.style.display === 'flex') {
                loadConversations();
            }
        })
        .subscribe();
}

// Chamar ao carregar a página
document.addEventListener('DOMContentLoaded', () => {
    setupMessagesRealtime();
    updateUnreadCount();
});
```

### 1.9 CSS Adicional

```css
/* Modal de Mensagens - Mobile */
@media (max-width: 768px) {
    #messagesModal .modal-container {
        max-width: 100%;
        width: 100%;
        height: 100vh;
        margin: 0;
        border-radius: 0;
    }
    
    .conversations-sidebar {
        width: 100% !important;
        display: none;
    }
    
    .conversations-sidebar.mobile-visible {
        display: block !important;
    }
    
    .chat-area {
        display: none !important;
    }
    
    .chat-area.mobile-visible {
        display: flex !important;
    }
}
```

### 1.10 Botão "Enviar Mensagem" em Perfis de Outros Usuários

Adicionar nos perfis (quando não é o próprio usuário):

```html
<button onclick="startConversationWithUser('${userId}')" style="
    background: #667eea;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    cursor: pointer;
    font-weight: 600;
    transition: background 0.2s;
" onmouseover="this.style.background='#5568d3'" onmouseout="this.style.background='#667eea'">
    💬 Enviar Mensagem
</button>
```

---

## 2️⃣ Configurações de Perfil (Card + Modal)

### 2.1 Localização

**Card na aba Perfil**, posicionado logo após o card de Mensagens.

### 2.2 Funções SQL

```sql
-- Atualizar perfil com validações
CREATE OR REPLACE FUNCTION public.update_user_profile(
    p_user_id UUID,
    p_name TEXT DEFAULT NULL,
    p_username VARCHAR(50) DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_username_exists BOOLEAN;
BEGIN
    -- Validar que é o próprio usuário
    IF p_user_id != auth.uid() THEN
        RETURN json_build_object('success', false, 'error', 'Você só pode atualizar seu próprio perfil');
    END IF;
    
    -- Validar username
    IF p_username IS NOT NULL THEN
        IF p_username !~ '^[a-zA-Z0-9_]+$' THEN
            RETURN json_build_object('success', false, 'error', 'Username deve conter apenas letras, números e underscore');
        END IF;
        
        IF LENGTH(p_username) < 3 OR LENGTH(p_username) > 50 THEN
            RETURN json_build_object('success', false, 'error', 'Username deve ter entre 3 e 50 caracteres');
        END IF;
        
        SELECT EXISTS(
            SELECT 1 FROM profiles 
            WHERE username = p_username AND id != p_user_id
        ) INTO v_username_exists;
        
        IF v_username_exists THEN
            RETURN json_build_object('success', false, 'error', 'Este username já está em uso');
        END IF;
    END IF;
    
    -- Validar nome
    IF p_name IS NOT NULL THEN
        IF LENGTH(TRIM(p_name)) < 2 THEN
            RETURN json_build_object('success', false, 'error', 'Nome deve ter pelo menos 2 caracteres');
        END IF;
    END IF;
    
    -- Atualizar
    UPDATE profiles
    SET 
        name = COALESCE(p_name, name),
        username = COALESCE(p_username, username),
        avatar_url = COALESCE(p_avatar_url, avatar_url),
        updated_at = now()
    WHERE id = p_user_id;
    
    RETURN json_build_object('success', true, 'message', 'Perfil atualizado com sucesso');
    
EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object('success', false, 'error', 'Username já está em uso');
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', 'Erro ao atualizar perfil: ' || SQLERRM);
END;
$$;

-- Verificar disponibilidade de username
CREATE OR REPLACE FUNCTION public.check_username_availability(
    p_username VARCHAR(50),
    p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM profiles 
        WHERE username = p_username 
          AND (p_user_id IS NULL OR id != p_user_id)
    ) INTO v_exists;
    
    RETURN NOT v_exists;
END;
$$;
```

### 2.3 Card na Aba Perfil

**Adicionar após o card de Mensagens:**

```html
<!-- Card de Configurações -->
<div class="settings-card-container" style="margin-top: 1rem; margin-bottom: 2rem;">
    <div class="stat-card settings-card" onclick="openSettingsModal()" style="
        cursor: pointer; 
        transition: transform 0.2s ease, box-shadow 0.2s ease; 
        box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
        border-radius: 12px;
        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        color: white;
        padding: 1.5rem;
    " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 4px 16px rgba(240, 147, 251, 0.3)';" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 2px 8px rgba(0,0,0,0.1)';">
        <div style="display: flex; align-items: center; gap: 1rem;">
            <div style="font-size: 2.5rem;">⚙️</div>
            <div>
                <div style="font-size: 1.2rem; font-weight: 600; margin-bottom: 0.25rem;">Configurações</div>
                <div style="font-size: 0.9rem; opacity: 0.9;">Edite seu perfil</div>
            </div>
        </div>
    </div>
</div>
```

### 2.4 Modal de Configurações

```html
<!-- Modal de Configurações -->
<div id="settingsModal" class="modal-overlay" style="display: none;">
    <div class="modal-container" style="max-width: 600px;" onclick="event.stopPropagation()">
        <div class="modal-header">
            <h2>⚙️ Configurações do Perfil</h2>
            <button class="close-btn" onclick="closeSettingsModal()">&times;</button>
        </div>
        <div class="modal-body" style="padding: 2rem;">
            <!-- Foto de Perfil -->
            <div class="settings-section" style="margin-bottom: 2rem; padding-bottom: 2rem; border-bottom: 1px solid #eee;">
                <h3 style="margin-bottom: 1rem; color: #333;">Foto de Perfil</h3>
                <div style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
                    <img id="settingsAvatarPreview" src="" alt="Avatar" style="
                        width: 100px;
                        height: 100px;
                        border-radius: 50%;
                        object-fit: cover;
                        border: 3px solid #e55a2b;
                        background: #f0f0f0;
                    ">
                    <input type="file" id="avatarInput" accept="image/*" style="display: none;">
                    <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                        <button onclick="document.getElementById('avatarInput').click()" style="
                            padding: 0.75rem 1.5rem;
                            background: #6c757d;
                            color: white;
                            border: none;
                            border-radius: 8px;
                            cursor: pointer;
                            font-weight: 600;
                        ">📷 Alterar Foto</button>
                        <button onclick="removeAvatar()" style="
                            padding: 0.75rem 1.5rem;
                            background: #dc3545;
                            color: white;
                            border: none;
                            border-radius: 8px;
                            cursor: pointer;
                            font-weight: 600;
                        ">🗑️ Remover</button>
                    </div>
                </div>
            </div>
            
            <!-- Nome -->
            <div class="settings-section" style="margin-bottom: 2rem; padding-bottom: 2rem; border-bottom: 1px solid #eee;">
                <h3 style="margin-bottom: 1rem; color: #333;">Nome</h3>
                <input 
                    type="text" 
                    id="settingsName" 
                    placeholder="Seu nome completo"
                    maxlength="100"
                    style="
                        width: 100%;
                        padding: 0.75rem;
                        border: 1px solid #ddd;
                        border-radius: 8px;
                        font-size: 1rem;
                    "
                >
                <small style="display: block; margin-top: 0.5rem; color: #666; font-size: 0.875rem;">
                    Como você quer ser chamado no HoloSpot
                </small>
            </div>
            
            <!-- Username -->
            <div class="settings-section" style="margin-bottom: 2rem; padding-bottom: 2rem; border-bottom: 1px solid #eee;">
                <h3 style="margin-bottom: 1rem; color: #333;">Username</h3>
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <span style="font-size: 1.2rem; color: #666; font-weight: bold;">@</span>
                    <input 
                        type="text" 
                        id="settingsUsername" 
                        placeholder="username"
                        maxlength="50"
                        pattern="[a-zA-Z0-9_]+"
                        style="
                            flex: 1;
                            padding: 0.75rem;
                            border: 1px solid #ddd;
                            border-radius: 8px;
                            font-size: 1rem;
                        "
                    >
                </div>
                <small style="display: block; margin-top: 0.5rem; color: #666; font-size: 0.875rem;">
                    Apenas letras, números e underscore (3-50 caracteres)
                </small>
                <div id="usernameAvailability" style="margin-top: 0.5rem; font-size: 0.875rem; font-weight: 600;"></div>
            </div>
            
            <!-- Email (somente leitura) -->
            <div class="settings-section" style="margin-bottom: 2rem;">
                <h3 style="margin-bottom: 1rem; color: #333;">Email</h3>
                <input 
                    type="email" 
                    id="settingsEmail" 
                    disabled
                    style="
                        width: 100%;
                        padding: 0.75rem;
                        border: 1px solid #ddd;
                        border-radius: 8px;
                        font-size: 1rem;
                        background: #f5f5f5;
                        cursor: not-allowed;
                    "
                >
                <small style="display: block; margin-top: 0.5rem; color: #666; font-size: 0.875rem;">
                    Email não pode ser alterado
                </small>
            </div>
            
            <!-- Botões -->
            <div style="display: flex; gap: 1rem; margin-top: 2rem;">
                <button onclick="saveProfileSettings()" style="
                    flex: 1;
                    padding: 1rem;
                    background: #e55a2b;
                    color: white;
                    border: none;
                    border-radius: 8px;
                    font-size: 1rem;
                    font-weight: 600;
                    cursor: pointer;
                ">💾 Salvar Alterações</button>
                <button onclick="closeSettingsModal()" style="
                    padding: 1rem 1.5rem;
                    background: #6c757d;
                    color: white;
                    border: none;
                    border-radius: 8px;
                    cursor: pointer;
                    font-weight: 600;
                ">❌ Cancelar</button>
            </div>
        </div>
    </div>
</div>
```

### 2.5 JavaScript - Funções

```javascript
// Abrir modal de configurações
async function openSettingsModal() {
    document.getElementById('settingsModal').style.display = 'flex';
    await loadProfileSettings();
}

// Fechar modal
function closeSettingsModal() {
    document.getElementById('settingsModal').style.display = 'none';
}

// Carregar dados atuais
async function loadProfileSettings() {
    const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', currentUser.id)
        .single();
    
    if (error) {
        console.error('Erro ao carregar perfil:', error);
        return;
    }
    
    document.getElementById('settingsName').value = profile.name || '';
    document.getElementById('settingsUsername').value = profile.username || '';
    document.getElementById('settingsEmail').value = profile.email || '';
    document.getElementById('settingsAvatarPreview').src = profile.avatar_url || '';
}

// Verificar username em tempo real
let usernameCheckTimeout;
document.getElementById('settingsUsername').addEventListener('input', (e) => {
    clearTimeout(usernameCheckTimeout);
    const username = e.target.value.trim();
    
    if (username.length < 3) {
        document.getElementById('usernameAvailability').textContent = '';
        return;
    }
    
    usernameCheckTimeout = setTimeout(async () => {
        const { data: isAvailable, error } = await supabase.rpc('check_username_availability', {
            p_username: username,
            p_user_id: currentUser.id
        });
        
        if (error) {
            console.error('Erro ao verificar username:', error);
            return;
        }
        
        const div = document.getElementById('usernameAvailability');
        if (isAvailable) {
            div.textContent = '✅ Username disponível';
            div.style.color = '#28a745';
        } else {
            div.textContent = '❌ Username já está em uso';
            div.style.color = '#dc3545';
        }
    }, 500);
});

// Upload de avatar
document.getElementById('avatarInput').addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    if (!file.type.startsWith('image/')) {
        showToast('Por favor, selecione uma imagem');
        return;
    }
    
    if (file.size > 2 * 1024 * 1024) {
        showToast('Imagem muito grande. Máximo 2MB');
        return;
    }
    
    const fileName = `${currentUser.id}_${Date.now()}.${file.name.split('.').pop()}`;
    const { data, error } = await supabase.storage
        .from('avatars')
        .upload(fileName, file, { cacheControl: '3600', upsert: true });
    
    if (error) {
        console.error('Erro ao fazer upload:', error);
        showToast('Erro ao fazer upload da imagem');
        return;
    }
    
    const { data: urlData } = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);
    
    document.getElementById('settingsAvatarPreview').src = urlData.publicUrl;
    showToast('Imagem carregada! Clique em "Salvar Alterações" para confirmar');
});

// Remover avatar
function removeAvatar() {
    document.getElementById('settingsAvatarPreview').src = '';
    showToast('Avatar removido! Clique em "Salvar Alterações" para confirmar');
}

// Salvar alterações
async function saveProfileSettings() {
    const name = document.getElementById('settingsName').value.trim();
    const username = document.getElementById('settingsUsername').value.trim();
    const avatarUrl = document.getElementById('settingsAvatarPreview').src;
    
    if (name.length < 2) {
        showToast('Nome deve ter pelo menos 2 caracteres');
        return;
    }
    
    if (username.length < 3) {
        showToast('Username deve ter pelo menos 3 caracteres');
        return;
    }
    
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
        showToast('Username deve conter apenas letras, números e underscore');
        return;
    }
    
    const { data: result, error } = await supabase.rpc('update_user_profile', {
        p_user_id: currentUser.id,
        p_name: name,
        p_username: username,
        p_avatar_url: avatarUrl || null
    });
    
    if (error) {
        console.error('Erro ao atualizar perfil:', error);
        showToast('Erro ao atualizar perfil');
        return;
    }
    
    if (!result.success) {
        showToast(result.error);
        return;
    }
    
    showToast('Perfil atualizado com sucesso! 🎉');
    
    // Recarregar dados do usuário
    await loadCurrentUser();
    
    // Fechar modal
    closeSettingsModal();
    
    // Recarregar aba de perfil
    loadUserProfile();
}
```

### 2.6 Storage (Supabase)

Criar bucket `avatars` e configurar políticas:

```sql
-- Política: Upload
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Política: Leitura pública
CREATE POLICY "Public avatar access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Política: Update
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## 3️⃣ Filtros de Feed (Aba Início)

### 3.1 Função SQL

```sql
CREATE OR REPLACE FUNCTION public.get_feed_posts(
    p_user_id UUID,
    p_filter_type TEXT DEFAULT 'all',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    person_name TEXT,
    mentioned_user_id UUID,
    content TEXT,
    story TEXT,
    photo_url TEXT,
    type TEXT,
    highlight_type TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    CASE p_filter_type
        WHEN 'all' THEN
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'following' THEN
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            INNER JOIN follows f ON f.following_id = p.user_id
            WHERE f.follower_id = p_user_id
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        WHEN 'recommended' THEN
            -- Por enquanto, mesmo que 'all'
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
        
        ELSE
            RETURN QUERY
            SELECT p.id, p.user_id, p.celebrated_person_name, p.person_name,
                   p.mentioned_user_id, p.content, p.story, p.photo_url,
                   p.type, p.highlight_type, p.created_at, p.updated_at
            FROM posts p
            ORDER BY p.created_at DESC
            LIMIT p_limit OFFSET p_offset;
    END CASE;
END;
$$;
```

### 3.2 HTML - Botões de Filtro

**Adicionar no início da aba Início (linha ~2618):**

```html
<div id="inicioTab" class="tab-content active">
    <!-- Filtros de Feed -->
    <div class="feed-filters" style="
        display: flex;
        gap: 0.5rem;
        padding: 1rem;
        background: white;
        border-bottom: 1px solid #eee;
        position: sticky;
        top: 0;
        z-index: 100;
    ">
        <button class="filter-btn active" data-filter="all" onclick="setFeedFilter('all')" style="
            flex: 1;
            padding: 0.75rem 1rem;
            background: linear-gradient(135deg, #e55a2b, #ffb700);
            color: white;
            border: 2px solid #e55a2b;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 600;
            transition: all 0.2s ease;
        ">
            🌍 Todos
        </button>
        <button class="filter-btn" data-filter="following" onclick="setFeedFilter('following')" style="
            flex: 1;
            padding: 0.75rem 1rem;
            background: #f5f5f5;
            color: #666;
            border: 2px solid transparent;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 600;
            transition: all 0.2s ease;
        ">
            👥 Seguindo
        </button>
        <button class="filter-btn" data-filter="recommended" onclick="setFeedFilter('recommended')" style="
            flex: 1;
            padding: 0.75rem 1rem;
            background: #f5f5f5;
            color: #666;
            border: 2px solid transparent;
            border-radius: 8px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 600;
            transition: all 0.2s ease;
        ">
            ✨ Recomendados
        </button>
    </div>
    
    <!-- Feed de Posts -->
    <div id="feed"></div>
</div>
```

### 3.3 JavaScript

```javascript
let currentFeedFilter = 'all';

function setFeedFilter(filter) {
    currentFeedFilter = filter;
    
    // Atualizar UI
    document.querySelectorAll('.filter-btn').forEach(btn => {
        if (btn.dataset.filter === filter) {
            btn.style.background = 'linear-gradient(135deg, #e55a2b, #ffb700)';
            btn.style.color = 'white';
            btn.style.borderColor = '#e55a2b';
            btn.classList.add('active');
        } else {
            btn.style.background = '#f5f5f5';
            btn.style.color = '#666';
            btn.style.borderColor = 'transparent';
            btn.classList.remove('active');
        }
    });
    
    localStorage.setItem('feedFilter', filter);
    loadFeed();
}

async function loadFeed() {
    const feedDiv = document.getElementById('feed');
    feedDiv.innerHTML = '<div style="text-align: center; padding: 2rem; color: #666;">Carregando posts...</div>';
    
    try {
        const { data: posts, error } = await supabase.rpc('get_feed_posts', {
            p_user_id: currentUser.id,
            p_filter_type: currentFeedFilter,
            p_limit: 50,
            p_offset: 0
        });
        
        if (error) {
            console.error('Erro ao carregar feed:', error);
            feedDiv.innerHTML = '<div style="text-align: center; padding: 2rem; color: #dc3545;">Erro ao carregar posts</div>';
            return;
        }
        
        if (posts.length === 0) {
            feedDiv.innerHTML = getEmptyFeedMessage(currentFeedFilter);
            return;
        }
        
        await renderPosts(posts);
        
    } catch (error) {
        console.error('Erro ao carregar feed:', error);
        feedDiv.innerHTML = '<div style="text-align: center; padding: 2rem; color: #dc3545;">Erro ao carregar posts</div>';
    }
}

function getEmptyFeedMessage(filter) {
    switch (filter) {
        case 'following':
            return `
                <div style="text-align: center; padding: 4rem 2rem; color: #666;">
                    <div style="font-size: 64px; margin-bottom: 1rem;">👥</div>
                    <h3 style="color: #333; margin-bottom: 1rem;">Nenhum post de quem você segue</h3>
                    <p style="margin-bottom: 2rem;">Comece seguindo pessoas para ver os posts delas aqui!</p>
                    <button onclick="showTab('buscar')" style="
                        background: #e55a2b;
                        color: white;
                        border: none;
                        padding: 1rem 2rem;
                        border-radius: 8px;
                        cursor: pointer;
                        font-weight: 600;
                        font-size: 1rem;
                    ">🔍 Buscar Pessoas</button>
                </div>
            `;
        case 'recommended':
            return `
                <div style="text-align: center; padding: 4rem 2rem; color: #666;">
                    <div style="font-size: 64px; margin-bottom: 1rem;">✨</div>
                    <h3 style="color: #333; margin-bottom: 1rem;">Nenhuma recomendação disponível</h3>
                    <p>Interaja mais com posts para receber recomendações personalizadas!</p>
                </div>
            `;
        default:
            return `
                <div style="text-align: center; padding: 4rem 2rem; color: #666;">
                    <div style="font-size: 64px; margin-bottom: 1rem;">📝</div>
                    <h3 style="color: #333; margin-bottom: 1rem;">Nenhum post ainda</h3>
                    <p>Seja o primeiro a destacar alguém!</p>
                </div>
            `;
    }
}

// Carregar filtro salvo ao iniciar
document.addEventListener('DOMContentLoaded', () => {
    const savedFilter = localStorage.getItem('feedFilter') || 'all';
    setFeedFilter(savedFilter);
});
```

### 3.4 CSS Mobile

```css
@media (max-width: 768px) {
    .feed-filters {
        padding: 0.75rem !important;
        gap: 0.25rem !important;
    }
    
    .filter-btn {
        padding: 0.5rem 0.75rem !important;
        font-size: 0.8rem !important;
    }
}
```

---

## 4️⃣ Resumo e Ordem de Implementação

### Complexidade e Tempo Estimado

| Funcionalidade | Complexidade | Tempo Estimado | Prioridade |
|----------------|--------------|----------------|------------|
| **Filtros de Feed** | ⭐ Baixa | 2-3 horas | 🔥 Alta |
| **Settings (Card + Modal)** | ⭐⭐ Média | 5-7 horas | 🔥 Alta |
| **Chat (Card + Modal)** | ⭐⭐⭐ Alta | 14-18 horas | 🟡 Média |

### Ordem Recomendada

1. **Filtros de Feed** (quick win)
2. **Settings** (necessário para UX)
3. **Chat** (feature mais complexa)

---

## 5️⃣ Checklist Completo

### Filtros de Feed
- [ ] Criar função `get_feed_posts` no SQL
- [ ] Adicionar HTML dos botões de filtro
- [ ] Implementar `setFeedFilter()` em JavaScript
- [ ] Implementar `loadFeed()` com filtro
- [ ] Adicionar CSS mobile
- [ ] Implementar persistência no localStorage
- [ ] Testar filtro "Todos"
- [ ] Testar filtro "Seguindo"
- [ ] Adicionar mensagens para feed vazio
- [ ] Testar em mobile

### Settings (Card + Modal)
- [ ] Criar função `update_user_profile` no SQL
- [ ] Criar função `check_username_availability` no SQL
- [ ] Criar bucket `avatars` no Supabase Storage
- [ ] Configurar políticas de storage
- [ ] Adicionar card na aba Perfil
- [ ] Adicionar modal HTML
- [ ] Implementar `openSettingsModal()`
- [ ] Implementar `loadProfileSettings()`
- [ ] Implementar `saveProfileSettings()`
- [ ] Implementar upload de avatar
- [ ] Implementar validação de username em tempo real
- [ ] Testar validações
- [ ] Testar upload de avatar
- [ ] Testar em mobile

### Chat (Card + Modal)
- [ ] Criar tabela `conversations`
- [ ] Criar tabela `conversation_participants`
- [ ] Criar tabela `messages`
- [ ] Criar função `get_or_create_conversation`
- [ ] Criar função `send_message`
- [ ] Criar função `mark_conversation_as_read`
- [ ] Criar função `get_total_unread_messages`
- [ ] Criar trigger de notificação
- [ ] Configurar RLS policies
- [ ] Adicionar card na aba Perfil
- [ ] Adicionar modal HTML
- [ ] Implementar `openMessagesModal()`
- [ ] Implementar `loadConversations()`
- [ ] Implementar `openConversation()`
- [ ] Implementar `sendMessage()`
- [ ] Implementar `updateUnreadCount()`
- [ ] Implementar `startConversationWithUser()`
- [ ] Implementar Realtime
- [ ] Adicionar botão "Enviar Mensagem" nos perfis
- [ ] Adicionar CSS mobile
- [ ] Testar criação de conversa
- [ ] Testar envio de mensagem
- [ ] Testar recebimento em tempo real
- [ ] Testar contador de não lidas
- [ ] Testar em mobile

---

## 6️⃣ Vantagens da Arquitetura Revisada

### UX
✅ **Menos clutter** na navegação principal  
✅ **Hub centralizado** no Perfil do usuário  
✅ **Padrão consistente** com cards existentes  
✅ **Melhor para mobile** (modais > abas)

### Desenvolvimento
✅ **Reutiliza padrões** já existentes  
✅ **Menos código** de navegação  
✅ **Mais fácil de manter**  
✅ **Escalável** (fácil adicionar novos cards)

### Performance
✅ **Lazy loading** (só carrega quando abre o modal)  
✅ **Menos peso inicial** da página  
✅ **Melhor cache** (modais reutilizáveis)

---

**Documento criado em:** 28 de outubro de 2025  
**Versão:** 2.0 (Revisado)  
**Autor:** Manus AI Assistant

