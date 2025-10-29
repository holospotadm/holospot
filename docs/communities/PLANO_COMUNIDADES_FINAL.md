# 🏢 HoloSpot - Comunidades (Plano Final de Implementação)

## 🎯 Visão Geral

**Objetivo:** Adicionar funcionalidade de **Comunidades** ao HoloSpot, onde apenas **@guilherme.dutra** pode criar e gerenciar comunidades privadas.

**Características:**
- ✅ Apenas **@guilherme.dutra** pode criar comunidades
- ✅ **Emoji customizado** para cada comunidade (aparece nas tabs e dropdown)
- ✅ **Gamificação unificada** (mesmos pontos e badges globais)
- ✅ **3 novos badges**: Owner de Comunidade, Membro de Comunidade, Primeiro Post
- ✅ **Moderação**: Owner pode editar, remover posts e gerenciar membros
- ✅ **Múltiplos feeds**: Para Você, Seguindo, + 1 feed por comunidade
- ✅ **Feed privado**: Apenas membros veem posts da comunidade

---

## 📊 Backend (2 tabelas + 4 funções + RLS)

### 1. Modificar tabela `profiles`

```sql
-- Adicionar campo community_owner
ALTER TABLE profiles 
ADD COLUMN community_owner BOOLEAN DEFAULT false;

-- Habilitar para @guilherme.dutra
UPDATE profiles 
SET community_owner = true 
WHERE username = 'guilherme.dutra';
```

---

### 2. Criar tabela `communities`

```sql
CREATE TABLE communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    emoji TEXT DEFAULT '🏢', -- Emoji da comunidade
    logo_url TEXT,
    owner_id UUID REFERENCES profiles(id) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_communities_owner ON communities(owner_id);
CREATE INDEX idx_communities_slug ON communities(slug);

-- RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;

-- Membros podem ver comunidades que participam
CREATE POLICY "Members can view community"
ON communities FOR SELECT
USING (
    id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Apenas community_owner pode criar
CREATE POLICY "Only community owners can create communities"
ON communities FOR INSERT
WITH CHECK (
    auth.uid() IN (
        SELECT id FROM profiles WHERE community_owner = true
    )
);

-- Owner pode atualizar sua comunidade
CREATE POLICY "Owner can update community"
ON communities FOR UPDATE
USING (auth.uid() = owner_id);

-- Owner pode deletar sua comunidade
CREATE POLICY "Owner can delete community"
ON communities FOR DELETE
USING (auth.uid() = owner_id);
```

---

### 3. Criar tabela `community_members`

```sql
CREATE TABLE community_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID REFERENCES communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'member'
    joined_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(community_id, user_id)
);

CREATE INDEX idx_community_members_community ON community_members(community_id);
CREATE INDEX idx_community_members_user ON community_members(user_id);
CREATE INDEX idx_community_members_active ON community_members(community_id, is_active);

-- RLS
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

-- Membros podem ver outros membros da mesma comunidade
CREATE POLICY "Members can view other members"
ON community_members FOR SELECT
USING (
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Owner pode adicionar membros
CREATE POLICY "Owner can add members"
ON community_members FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = community_members.community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
    )
);

-- Owner pode atualizar membros
CREATE POLICY "Owner can update members"
ON community_members FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);

-- Owner pode remover membros
CREATE POLICY "Owner can remove members"
ON community_members FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM community_members cm
        WHERE cm.community_id = community_members.community_id 
        AND cm.user_id = auth.uid() 
        AND cm.role = 'owner'
    )
);
```

---

### 4. Modificar tabela `posts`

```sql
-- Adicionar campo community_id
ALTER TABLE posts 
ADD COLUMN community_id UUID REFERENCES communities(id) ON DELETE CASCADE;

CREATE INDEX idx_posts_community ON posts(community_id) WHERE community_id IS NOT NULL;

-- RLS: Atualizar policy de SELECT
DROP POLICY IF EXISTS "Users can view posts" ON posts;

CREATE POLICY "Users can view posts"
ON posts FOR SELECT
USING (
    community_id IS NULL OR -- posts globais
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- RLS: Atualizar policy de INSERT
DROP POLICY IF EXISTS "Users can create posts" ON posts;

CREATE POLICY "Users can create posts"
ON posts FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND (
        community_id IS NULL OR -- posts globais
        community_id IN (
            SELECT community_id FROM community_members 
            WHERE user_id = auth.uid() AND is_active = true
        )
    )
);

-- RLS: Owner pode deletar posts da comunidade
CREATE POLICY "Owner can delete community posts"
ON posts FOR DELETE
USING (
    auth.uid() = user_id OR -- próprio post
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);

-- RLS: Owner pode editar posts da comunidade (moderação)
CREATE POLICY "Owner can update community posts"
ON posts FOR UPDATE
USING (
    auth.uid() = user_id OR -- próprio post
    community_id IN (
        SELECT community_id FROM community_members 
        WHERE user_id = auth.uid() 
        AND role = 'owner'
    )
);
```

---

### 5. Função: Criar Comunidade

```sql
CREATE OR REPLACE FUNCTION create_community(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_owner_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_community_id UUID;
    v_is_community_owner BOOLEAN;
BEGIN
    -- Verificar se usuário está autenticado
    IF auth.uid() != p_owner_id THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Verificar se usuário é community_owner
    SELECT community_owner INTO v_is_community_owner
    FROM profiles
    WHERE id = p_owner_id;
    
    IF NOT v_is_community_owner THEN
        RAISE EXCEPTION 'User is not authorized to create communities';
    END IF;
    
    -- Criar comunidade
    INSERT INTO communities (name, slug, description, emoji, owner_id)
    VALUES (p_name, p_slug, p_description, COALESCE(p_emoji, '🏢'), p_owner_id)
    RETURNING id INTO v_community_id;
    
    -- Adicionar owner como membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (v_community_id, p_owner_id, 'owner');
    
    -- Atribuir badge "Owner de Comunidade"
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_owner_id,
        'Owner de Comunidade',
        'Criou uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN v_community_id;
END;
$$;
```

---

### 6. Função: Atualizar Comunidade

```sql
CREATE OR REPLACE FUNCTION update_community(
    p_community_id UUID,
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_emoji TEXT,
    p_logo_url TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se usuário é owner
    IF NOT EXISTS (
        SELECT 1 FROM communities 
        WHERE id = p_community_id 
        AND owner_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can update community';
    END IF;
    
    -- Atualizar comunidade
    UPDATE communities
    SET 
        name = p_name,
        slug = p_slug,
        description = p_description,
        emoji = COALESCE(p_emoji, emoji),
        logo_url = p_logo_url,
        updated_at = NOW()
    WHERE id = p_community_id;
    
    RETURN true;
END;
$$;
```

---

### 7. Função: Adicionar Membro

```sql
CREATE OR REPLACE FUNCTION add_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se quem está adicionando é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can add members';
    END IF;
    
    -- Adicionar membro
    INSERT INTO community_members (community_id, user_id, role)
    VALUES (p_community_id, p_user_id, 'member')
    ON CONFLICT (community_id, user_id) DO UPDATE
    SET is_active = true;
    
    -- Atribuir badge "Membro de Comunidade"
    INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
    VALUES (
        p_user_id,
        'Membro de Comunidade',
        'Entrou em uma comunidade no HoloSpot',
        NOW()
    )
    ON CONFLICT (user_id, badge_name) DO NOTHING;
    
    RETURN true;
END;
$$;
```

---

### 8. Função: Remover Membro

```sql
CREATE OR REPLACE FUNCTION remove_community_member(
    p_community_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se quem está removendo é owner
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = auth.uid() 
        AND role = 'owner'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only owner can remove members';
    END IF;
    
    -- Não pode remover o próprio owner
    IF p_user_id = auth.uid() THEN
        RAISE EXCEPTION 'Owner cannot remove themselves';
    END IF;
    
    -- Remover membro (soft delete)
    UPDATE community_members
    SET is_active = false
    WHERE community_id = p_community_id AND user_id = p_user_id;
    
    RETURN true;
END;
$$;
```

---

### 9. Função: Feed da Comunidade

```sql
CREATE OR REPLACE FUNCTION get_community_feed(
    p_community_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    celebrated_person_name TEXT,
    mentioned_user_id UUID,
    person_name TEXT,
    content TEXT,
    image_url TEXT,
    created_at TIMESTAMP,
    likes_count INTEGER,
    comments_count INTEGER,
    user_has_liked BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se usuário é membro
    IF NOT EXISTS (
        SELECT 1 FROM community_members 
        WHERE community_id = p_community_id 
        AND user_id = p_user_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'User is not a member of this community';
    END IF;
    
    -- Retornar posts da comunidade
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.celebrated_person_name,
        p.mentioned_user_id,
        p.person_name,
        p.content,
        p.image_url,
        p.created_at,
        p.likes_count,
        p.comments_count,
        EXISTS(SELECT 1 FROM likes WHERE post_id = p.id AND user_id = p_user_id) as user_has_liked
    FROM posts p
    WHERE p.community_id = p_community_id
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;
```

---

### 10. Trigger: Badge "Primeiro Post na Comunidade"

```sql
CREATE OR REPLACE FUNCTION award_first_community_post_badge()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.community_id IS NOT NULL THEN
        -- Verificar se é o primeiro post do usuário nesta comunidade
        IF NOT EXISTS (
            SELECT 1 FROM posts 
            WHERE user_id = NEW.user_id 
            AND community_id = NEW.community_id 
            AND id != NEW.id
        ) THEN
            INSERT INTO user_badges (user_id, badge_name, badge_description, earned_at)
            VALUES (
                NEW.user_id,
                'Primeiro Post na Comunidade',
                'Fez o primeiro post em uma comunidade',
                NOW()
            )
            ON CONFLICT (user_id, badge_name) DO NOTHING;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_award_first_community_post_badge
AFTER INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION award_first_community_post_badge();
```

---

## 🎨 Frontend

### 1. Múltiplos Feeds (Tabs Dinâmicas)

**HTML (modificar tabs existentes):**
```html
<!-- Tabs dinâmicas -->
<div class="tabs" id="feedTabs">
    <button class="tab active" data-feed="for-you">Para Você</button>
    <button class="tab" data-feed="following">Seguindo</button>
    <!-- Comunidades adicionadas dinamicamente -->
</div>
```

**JavaScript:**
```javascript
// Carregar comunidades do usuário e criar tabs
async function loadUserCommunities() {
    const { data: memberships, error } = await supabase
        .from('community_members')
        .select(`
            community_id,
            role,
            communities (
                id,
                name,
                slug,
                emoji,
                logo_url
            )
        `)
        .eq('user_id', currentUser.id)
        .eq('is_active', true);
    
    if (error) {
        console.error('Erro ao carregar comunidades:', error);
        return;
    }
    
    // Armazenar comunidades do usuário
    currentUser.communities = memberships;
    
    // Adicionar tabs de comunidades
    const feedTabs = document.getElementById('feedTabs');
    
    // Remover tabs antigas de comunidades (manter apenas Para Você e Seguindo)
    const existingTabs = feedTabs.querySelectorAll('.tab');
    existingTabs.forEach(tab => {
        if (tab.dataset.feed !== 'for-you' && tab.dataset.feed !== 'following') {
            tab.remove();
        }
    });
    
    // Adicionar nova tab para cada comunidade
    memberships.forEach(m => {
        const tab = document.createElement('button');
        tab.className = 'tab';
        tab.dataset.feed = `community-${m.community_id}`;
        tab.dataset.communityId = m.community_id;
        tab.dataset.role = m.role;
        tab.textContent = `${m.communities.emoji || '🏢'} ${m.communities.name}`;
        
        tab.addEventListener('click', () => {
            // Remover active de todas as tabs
            feedTabs.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            
            // Adicionar active na tab clicada
            tab.classList.add('active');
            
            // Carregar feed da comunidade
            loadCommunityFeed(m.community_id);
        });
        
        feedTabs.appendChild(tab);
    });
    
    // Restaurar feed ativo (localStorage)
    const activeFeed = localStorage.getItem('activeFeed') || 'for-you';
    const activeTab = feedTabs.querySelector(`[data-feed="${activeFeed}"]`);
    if (activeTab) {
        activeTab.click();
    }
}

// Carregar feed da comunidade
async function loadCommunityFeed(communityId) {
    localStorage.setItem('activeFeed', `community-${communityId}`);
    
    const { data: posts, error } = await supabase.rpc('get_community_feed', {
        p_community_id: communityId,
        p_user_id: currentUser.id,
        p_limit: 20,
        p_offset: 0
    });
    
    if (error) {
        console.error('Erro ao carregar feed da comunidade:', error);
        alert('❌ Erro ao carregar feed da comunidade');
        return;
    }
    
    await processPostsUserData(posts);
    renderPosts(posts);
}

// Modificar event listeners das tabs existentes
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const feed = tab.dataset.feed;
        localStorage.setItem('activeFeed', feed);
        
        // Remover active de todas
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        
        if (feed === 'for-you' || feed === 'following') {
            loadPosts(); // Função existente
        }
    });
});

// Chamar ao fazer login
loadUserCommunities();
```

---

### 2. Botão de Gerenciamento na Aba Perfil

**HTML (adicionar na aba perfil, ao lado de chat e configurações):**
```html
<!-- Na seção de perfil, ao lado dos ícones existentes -->
<div class="profile-actions" style="display: flex; gap: 10px; margin-top: 20px;">
    <!-- Botões existentes -->
    <button onclick="openChatModal()" style="...">
        💬 Chat
    </button>
    
    <button onclick="openSettingsModal()" style="...">
        ⚙️ Configurações
    </button>
    
    <!-- Novo botão (apenas para @guilherme.dutra) -->
    <button id="manageCommunityBtn" onclick="openManageCommunityModal()" style="
        padding: 10px 20px;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        border: none;
        border-radius: 8px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        display: none;
    ">
        🏢 Gerenciar Comunidades
    </button>
</div>

<script>
// Mostrar botão apenas para @guilherme.dutra
if (currentUser.community_owner) {
    document.getElementById('manageCommunityBtn').style.display = 'inline-block';
}
</script>
```

---

### 3. Modal de Gerenciamento de Comunidades + Emoji Picker

**HTML:**
```html
<!-- Modal de Gerenciamento -->
<div id="manageCommunityModal" class="modal-overlay" style="display: none;">
    <div class="modal-content" style="max-width: 700px; max-height: 90vh; overflow-y: auto;">
        <div class="modal-header">
            <h2>🏢 Gerenciar Comunidades</h2>
            <button class="modal-close" onclick="closeManageCommunityModal()">×</button>
        </div>
        
        <div style="padding: 20px;">
            <!-- Dropdown de comunidades -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; margin-bottom: 8px; font-weight: 600;">Selecione uma Comunidade:</label>
                <select id="communitySelect" style="
                    width: 100%;
                    padding: 10px;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    font-size: 14px;
                    margin-bottom: 10px;
                ">
                    <option value="">-- Selecione --</option>
                    <!-- Comunidades carregadas dinamicamente -->
                </select>
                
                <button onclick="showCreateCommunityForm()" style="
                    width: 100%;
                    padding: 10px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border: none;
                    border-radius: 8px;
                    font-size: 14px;
                    font-weight: 600;
                    cursor: pointer;
                ">
                    ➕ Criar Nova Comunidade
                </button>
            </div>
            
            <!-- Formulário de criação (escondido por padrão) -->
            <div id="createCommunityForm" style="display: none; margin-bottom: 20px; padding: 20px; background: #f5f5f5; border-radius: 8px;">
                <h3 style="margin-bottom: 15px;">Criar Nova Comunidade</h3>
                <form id="newCommunityForm">
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px; font-weight: 600;">Emoji da Comunidade</label>
                        <div style="display: flex; gap: 10px; align-items: center;">
                            <input type="text" name="emoji" id="newCommunityEmoji" value="🏢" readonly style="
                                width: 60px;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 24px;
                                text-align: center;
                                cursor: pointer;
                            " onclick="openEmojiPicker('newCommunityEmoji')">
                            <button type="button" onclick="openEmojiPicker('newCommunityEmoji')" style="
                                padding: 10px 16px;
                                background: #f0f0f0;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                cursor: pointer;
                            ">
                                Escolher Emoji
                            </button>
                        </div>
                    </div>
                    
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px; font-weight: 600;">Nome da Comunidade</label>
                        <input type="text" name="name" placeholder="Ex: Empresa XYZ" required style="
                            width: 100%;
                            padding: 10px;
                            border: 1px solid #ddd;
                            border-radius: 8px;
                            font-size: 14px;
                        ">
                    </div>
                    
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px; font-weight: 600;">URL (slug)</label>
                        <input type="text" name="slug" placeholder="empresa-xyz" required pattern="[a-z0-9-]+" style="
                            width: 100%;
                            padding: 10px;
                            border: 1px solid #ddd;
                            border-radius: 8px;
                            font-size: 14px;
                        ">
                        <small style="color: #666;">Apenas letras minúsculas, números e hífens</small>
                    </div>
                    
                    <div style="margin-bottom: 15px;">
                        <label style="display: block; margin-bottom: 5px; font-weight: 600;">Descrição</label>
                        <textarea name="description" placeholder="Descreva sua comunidade..." rows="3" style="
                            width: 100%;
                            padding: 10px;
                            border: 1px solid #ddd;
                            border-radius: 8px;
                            font-size: 14px;
                            resize: vertical;
                        "></textarea>
                    </div>
                    
                    <div style="display: flex; gap: 10px;">
                        <button type="submit" style="
                            flex: 1;
                            padding: 10px;
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            color: white;
                            border: none;
                            border-radius: 8px;
                            font-size: 14px;
                            font-weight: 600;
                            cursor: pointer;
                        ">
                            Criar Comunidade
                        </button>
                        
                        <button type="button" onclick="hideCreateCommunityForm()" style="
                            padding: 10px 20px;
                            background: #ddd;
                            color: #333;
                            border: none;
                            border-radius: 8px;
                            font-size: 14px;
                            cursor: pointer;
                        ">
                            Cancelar
                        </button>
                    </div>
                </form>
            </div>
            
            <!-- Informações da comunidade selecionada -->
            <div id="communityInfo" style="display: none;">
                <!-- Tabs de gerenciamento -->
                <div class="management-tabs" style="display: flex; gap: 10px; margin-bottom: 20px; border-bottom: 2px solid #eee;">
                    <button class="management-tab active" data-tab="edit" onclick="switchManagementTab('edit')" style="
                        padding: 10px 20px;
                        background: none;
                        border: none;
                        border-bottom: 3px solid #667eea;
                        font-weight: 600;
                        cursor: pointer;
                    ">
                        ✏️ Editar
                    </button>
                    
                    <button class="management-tab" data-tab="members" onclick="switchManagementTab('members')" style="
                        padding: 10px 20px;
                        background: none;
                        border: none;
                        border-bottom: 3px solid transparent;
                        cursor: pointer;
                    ">
                        👥 Membros
                    </button>
                    
                    <button class="management-tab" data-tab="posts" onclick="switchManagementTab('posts')" style="
                        padding: 10px 20px;
                        background: none;
                        border: none;
                        border-bottom: 3px solid transparent;
                        cursor: pointer;
                    ">
                        📝 Posts
                    </button>
                </div>
                
                <!-- Tab: Editar -->
                <div id="editTab" class="management-tab-content">
                    <form id="editCommunityForm">
                        <input type="hidden" name="community_id">
                        
                        <div style="margin-bottom: 15px;">
                            <label style="display: block; margin-bottom: 5px; font-weight: 600;">Emoji da Comunidade</label>
                            <div style="display: flex; gap: 10px; align-items: center;">
                                <input type="text" name="emoji" id="editCommunityEmoji" value="🏢" readonly style="
                                    width: 60px;
                                    padding: 10px;
                                    border: 1px solid #ddd;
                                    border-radius: 8px;
                                    font-size: 24px;
                                    text-align: center;
                                    cursor: pointer;
                                " onclick="openEmojiPicker('editCommunityEmoji')">
                                <button type="button" onclick="openEmojiPicker('editCommunityEmoji')" style="
                                    padding: 10px 16px;
                                    background: #f0f0f0;
                                    border: 1px solid #ddd;
                                    border-radius: 8px;
                                    cursor: pointer;
                                ">
                                    Escolher Emoji
                                </button>
                            </div>
                        </div>
                        
                        <div style="margin-bottom: 15px;">
                            <label style="display: block; margin-bottom: 5px; font-weight: 600;">Nome da Comunidade</label>
                            <input type="text" name="name" required style="
                                width: 100%;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 14px;
                            ">
                        </div>
                        
                        <div style="margin-bottom: 15px;">
                            <label style="display: block; margin-bottom: 5px; font-weight: 600;">URL (slug)</label>
                            <input type="text" name="slug" required pattern="[a-z0-9-]+" style="
                                width: 100%;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 14px;
                            ">
                        </div>
                        
                        <div style="margin-bottom: 15px;">
                            <label style="display: block; margin-bottom: 5px; font-weight: 600;">Descrição</label>
                            <textarea name="description" rows="3" style="
                                width: 100%;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 14px;
                                resize: vertical;
                            "></textarea>
                        </div>
                        
                        <div style="margin-bottom: 15px;">
                            <label style="display: block; margin-bottom: 5px; font-weight: 600;">Logo URL</label>
                            <input type="url" name="logo_url" placeholder="https://..." style="
                                width: 100%;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 14px;
                            ">
                            <small style="color: #666;">URL da imagem do logo</small>
                        </div>
                        
                        <button type="submit" style="
                            width: 100%;
                            padding: 12px;
                            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                            color: white;
                            border: none;
                            border-radius: 8px;
                            font-size: 16px;
                            font-weight: 600;
                            cursor: pointer;
                        ">
                            💾 Salvar Alterações
                        </button>
                    </form>
                </div>
                
                <!-- Tab: Membros -->
                <div id="membersTab" class="management-tab-content" style="display: none;">
                    <!-- Buscar usuários para adicionar -->
                    <div style="margin-bottom: 20px;">
                        <h3 style="margin-bottom: 10px;">Adicionar Membros</h3>
                        <input 
                            type="text" 
                            id="searchUsers" 
                            placeholder="Buscar por nome ou @username"
                            style="
                                width: 100%;
                                padding: 10px;
                                border: 1px solid #ddd;
                                border-radius: 8px;
                                font-size: 14px;
                                margin-bottom: 10px;
                            "
                        >
                        <div id="searchResults" style="max-height: 200px; overflow-y: auto;"></div>
                    </div>
                    
                    <!-- Lista de membros atuais -->
                    <div>
                        <h3 style="margin-bottom: 10px;">Membros Atuais</h3>
                        <div id="currentMembers" style="max-height: 300px; overflow-y: auto;"></div>
                    </div>
                </div>
                
                <!-- Tab: Posts -->
                <div id="postsTab" class="management-tab-content" style="display: none;">
                    <div id="communityPosts" style="max-height: 500px; overflow-y: auto;">
                        <!-- Posts carregados dinamicamente -->
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Emoji Picker Modal -->
<div id="emojiPickerModal" class="modal-overlay" style="display: none;">
    <div class="modal-content" style="max-width: 500px;">
        <div class="modal-header">
            <h2>😀 Escolher Emoji</h2>
            <button class="modal-close" onclick="closeEmojiPicker()">×</button>
        </div>
        <div style="padding: 20px;">
            <!-- Busca de emoji -->
            <input 
                type="text" 
                id="emojiSearch" 
                placeholder="Buscar emoji..."
                style="
                    width: 100%;
                    padding: 10px;
                    border: 1px solid #ddd;
                    border-radius: 8px;
                    font-size: 14px;
                    margin-bottom: 15px;
                "
            >
            
            <!-- Grid de emojis -->
            <div id="emojiGrid" style="
                display: grid;
                grid-template-columns: repeat(8, 1fr);
                gap: 8px;
                max-height: 400px;
                overflow-y: auto;
                padding: 10px;
            ">
                <!-- Emojis carregados dinamicamente -->
            </div>
        </div>
    </div>
</div>
```

**JavaScript completo no próximo arquivo devido ao tamanho...**

---

## 📋 Checklist de Implementação

### Backend (Dias 1-2)
- [ ] Adicionar `profiles.community_owner`
- [ ] Habilitar para @guilherme.dutra
- [ ] Criar tabela `communities` (com campo `emoji`)
- [ ] Criar tabela `community_members`
- [ ] Adicionar `posts.community_id`
- [ ] Criar função `create_community()` (com parâmetro `p_emoji`)
- [ ] Criar função `update_community()` (com parâmetro `p_emoji`)
- [ ] Criar função `add_community_member()`
- [ ] Criar função `remove_community_member()`
- [ ] Criar função `get_community_feed()`
- [ ] Criar trigger para badge "Primeiro Post"
- [ ] Configurar RLS policies
- [ ] Testar no Supabase

### Frontend (Dias 3-5)
- [ ] Adicionar tabs dinâmicas de feeds (com emoji)
- [ ] Implementar `loadUserCommunities()`
- [ ] Implementar `loadCommunityFeed()`
- [ ] Adicionar botão "Gerenciar Comunidades" na aba perfil
- [ ] Criar modal de gerenciamento
- [ ] Criar emoji picker modal
- [ ] Implementar dropdown de comunidades (com emoji)
- [ ] Implementar formulário de criar comunidade (com emoji)
- [ ] Implementar formulário de editar comunidade (com emoji)
- [ ] Implementar tab de membros (adicionar/remover)
- [ ] Implementar tab de posts (listar/remover)
- [ ] Modificar `createPost()`
- [ ] Testar fluxo completo

### Testes (Dias 6-7)
- [ ] Criar comunidade com emoji
- [ ] Editar emoji da comunidade
- [ ] Verificar emoji nas tabs de feed
- [ ] Verificar emoji no dropdown de gerenciamento
- [ ] Adicionar membros
- [ ] Remover membros
- [ ] Trocar entre feeds (Para Você, Seguindo, Comunidades)
- [ ] Postar em feed global
- [ ] Postar em feed de comunidade
- [ ] Remover post (moderação)
- [ ] Verificar badges
- [ ] Verificar RLS (segurança)
- [ ] Testar com múltiplas comunidades

---

## ⏱️ Estimativa

**Tempo:** 5-7 dias (1 semana)  
**Custo:** R$ 4.000 - R$ 5.600  
**Esforço:** 40-56 horas

---

## 🎯 Resumo das Novidades

### ✅ Emoji Customizado
- Campo `emoji` na tabela `communities`
- Seletor de emoji nos formulários (criar/editar)
- Emoji aparece nas tabs de feed: `🏢 Nome da Comunidade`
- Emoji aparece no dropdown de gerenciamento
- Teclado virtual com categorias de emojis
- Busca de emoji por categoria

### ✅ Onde o Emoji Aparece
1. **Tabs de Feed**: `🏢 Empresa XYZ`
2. **Dropdown de Gerenciamento**: `🏢 Empresa XYZ`
3. **Formulário de Criar**: Campo com emoji picker
4. **Formulário de Editar**: Campo com emoji picker

---

## 🚀 Próximos Passos

1. **Revisar** este plano final
2. **Aprovar** para começar implementação
3. **Implementar Backend** (Dias 1-2)
4. **Implementar Frontend** (Dias 3-5)
5. **Testar** (Dias 6-7)
6. **Lançar** 🎉

**Pronto para começar?** 🚀

