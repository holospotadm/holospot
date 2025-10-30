/**
 * ============================================
 * MÓDULO: Community Management
 * Descrição: Gerenciamento de comunidades (criar, editar, membros, posts)
 * Autor: HoloSpot Team
 * Data: 2024-10-29
 * ============================================
 */

// ========== GERENCIAMENTO DE COMUNIDADES ==========

function openManageCommunityModal() {
    const modal = document.getElementById('manageCommunityModal');
    if (!modal) {
        console.error('Modal manageCommunityModal não encontrado');
        return;
    }
    
    modal.style.display = 'flex';
    loadOwnedCommunities();
}

function closeManageCommunityModal() {
    const modal = document.getElementById('manageCommunityModal');
    if (modal) {
        modal.style.display = 'none';
    }
    
    const select = document.getElementById('communitySelect');
    if (select) {
        select.value = '';
    }
    
    const info = document.getElementById('communityInfo');
    if (info) {
        info.style.display = 'none';
    }
    
    hideCreateCommunityForm();
}

// Carregar comunidades que o usuário é owner
async function loadOwnedCommunities() {
    if (!currentUser || !currentUser.id) {
        console.error('Usuário não autenticado');
        return;
    }

    const { data: communities, error } = await supabase
        .from('communities')
        .select('*')
        .eq('owner_id', currentUser.id)
        .eq('is_active', true)
        .order('created_at', { ascending: false });
    
    if (error) {
        console.error('Erro ao carregar comunidades:', error);
        return;
    }
    
    const select = document.getElementById('communitySelect');
    if (!select) return;
    
    select.innerHTML = '<option value="">-- Selecione --</option>';
    
    communities.forEach(community => {
        const option = document.createElement('option');
        option.value = community.id;
        option.textContent = `${community.emoji || '🏢'} ${community.name}`;
        option.dataset.community = JSON.stringify(community);
        select.appendChild(option);
    });
}

// Ao selecionar comunidade
function setupCommunitySelectListener() {
    const select = document.getElementById('communitySelect');
    if (!select) return;
    
    select.addEventListener('change', (e) => {
        const option = e.target.options[e.target.selectedIndex];
        
        if (option.value) {
            const community = JSON.parse(option.dataset.community);
            showCommunityInfo(community);
        } else {
            const info = document.getElementById('communityInfo');
            if (info) {
                info.style.display = 'none';
            }
        }
    });
}

// Mostrar informações da comunidade
function showCommunityInfo(community) {
    const info = document.getElementById('communityInfo');
    if (info) {
        info.style.display = 'block';
    }
    
    // Preencher dados da comunidade (com null checks)
    const nameInput = document.getElementById('editCommunityName');
    const descInput = document.getElementById('editCommunityDescription');
    const emojiSpan = document.getElementById('selectedEmoji');
    
    if (nameInput) nameInput.value = community.name;
    if (descInput) descInput.value = community.description || '';
    if (emojiSpan) emojiSpan.textContent = community.emoji || '🏢';
    
    // Carregar membros
    loadCommunityMembers(community.id);
    
    // Carregar posts
    loadCommunityPosts(community.id);
}

// ========== CRIAR COMUNIDADE ==========

function showCreateCommunityForm() {
    const form = document.getElementById('createCommunityForm');
    if (form) {
        form.style.display = 'block';
    }
}

function hideCreateCommunityForm() {
    const form = document.getElementById('createCommunityForm');
    if (form) {
        form.style.display = 'none';
        // Limpar campos manualmente se não for um form
        const nameInput = document.getElementById('newCommunityName');
        const descInput = document.getElementById('newCommunityDescription');
        const emojiSpan = document.getElementById('newCommunityEmoji');
        
        if (nameInput) nameInput.value = '';
        if (descInput) descInput.value = '';
        if (emojiSpan) emojiSpan.textContent = '🏢';
    }
}

async function createCommunity() {
    const name = document.getElementById('newCommunityName').value.trim();
    const description = document.getElementById('newCommunityDescription').value.trim();
    const emoji = document.getElementById('newCommunityEmoji').textContent;
    
    if (!name) {
        alert('Por favor, preencha o nome da comunidade');
        return;
    }
    
    const { data, error } = await supabase
        .from('communities')
        .insert({
            name,
            description,
            emoji,
            owner_id: currentUser.id
        })
        .select()
        .single();
    
    if (error) {
        console.error('Erro ao criar comunidade:', error);
        alert('Erro ao criar comunidade: ' + error.message);
        return;
    }
    
    // Adicionar owner como membro da comunidade
    const { error: memberError } = await supabase.rpc('add_community_member', {
        p_community_id: data.id,
        p_user_id: currentUser.id,
        p_role: 'owner'
    });
    
    if (memberError) {
        console.error('Erro ao adicionar owner como membro:', memberError);
        // Não bloqueia, apenas loga o erro
    }
    
    alert('✅ Comunidade criada com sucesso!');
    hideCreateCommunityForm();
    loadOwnedCommunities();
}

// ========== EDITAR COMUNIDADE ==========

async function updateCommunity() {
    const communityId = document.getElementById('communitySelect').value;
    if (!communityId) return;
    
    const name = document.getElementById('editCommunityName').value.trim();
    const description = document.getElementById('editCommunityDescription').value.trim();
    const emoji = document.getElementById('selectedEmoji').textContent;
    
    if (!name) {
        alert('Por favor, preencha o nome da comunidade');
        return;
    }
    
    const { error } = await supabase
        .from('communities')
        .update({ name, description, emoji })
        .eq('id', communityId);
    
    if (error) {
        console.error('Erro ao atualizar comunidade:', error);
        alert('Erro ao atualizar comunidade: ' + error.message);
        return;
    }
    
    alert('✅ Comunidade atualizada com sucesso!');
    loadOwnedCommunities();
}

// ========== EMOJI PICKER ==========

function openEmojiPicker(targetId) {
    const picker = document.getElementById('emojiPicker');
    if (!picker) return;
    
    picker.dataset.target = targetId;
    picker.style.display = 'block';
}

function closeEmojiPicker() {
    const picker = document.getElementById('emojiPicker');
    if (picker) {
        picker.style.display = 'none';
    }
}

function selectEmoji(emoji) {
    const picker = document.getElementById('emojiPicker');
    const targetId = picker.dataset.target;
    
    const target = document.getElementById(targetId);
    if (target) {
        target.textContent = emoji;
    }
    
    closeEmojiPicker();
}

// ========== TABS ==========

function switchManagementTab(tabName) {
    // Esconder todas as tabs
    document.querySelectorAll('.management-tab-content').forEach(tab => {
        tab.style.display = 'none';
    });
    
    // Remover active de todos os botões
    document.querySelectorAll('.management-tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Mostrar tab selecionada
    const selectedTab = document.getElementById(tabName + 'Tab');
    if (selectedTab) {
        selectedTab.style.display = 'block';
    }
    
    // Adicionar active ao botão correto (buscar por onclick)
    document.querySelectorAll('.management-tab-btn').forEach(btn => {
        const onclick = btn.getAttribute('onclick');
        if (onclick && onclick.includes(`'${tabName}'`)) {
            btn.classList.add('active');
        }
    });
}

// ========== MEMBROS ==========

async function loadCommunityMembers(communityId) {
    // Buscar informações da comunidade para saber quem é o owner
    const { data: community } = await supabase
        .from('communities')
        .select('owner_id')
        .eq('id', communityId)
        .single();
    
    const ownerId = community?.owner_id;
    
    // Buscar todos os membros (incluindo owner)
    const { data: members, error } = await supabase
        .from('community_members')
        .select(`
            user_id,
            role,
            joined_at,
            profiles:user_id (
                id,
                name,
                username,
                avatar_url
            )
        `)
        .eq('community_id', communityId)
        .eq('is_active', true)
        .order('joined_at', { ascending: true });
    
    if (error) {
        console.error('Erro ao carregar membros:', error);
        return;
    }
    
    const container = document.getElementById('currentMembers');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!members || members.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #666;">Nenhum membro ainda</p>';
        return;
    }
    
    // Ordenar: owner primeiro, depois outros membros
    const sortedMembers = [...members].sort((a, b) => {
        if (a.user_id === ownerId) return -1;
        if (b.user_id === ownerId) return 1;
        return 0;
    });
    
    sortedMembers.forEach(member => {
        const user = member.profiles;
        if (!user) return;
        
        const isOwner = user.id === ownerId;
        
        const memberDiv = document.createElement('div');
        memberDiv.style.cssText = `
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px;
            border-bottom: 1px solid #eee;
        `;
        
        memberDiv.innerHTML = `
            <img src="${user.avatar_url || 'https://via.placeholder.com/40'}" style="
                width: 40px;
                height: 40px;
                border-radius: 50%;
                object-fit: cover;
            ">
            <div style="flex: 1;">
                <div style="font-weight: 600;">
                    ${user.name}
                    ${isOwner ? '<span style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px;">OWNER</span>' : ''}
                </div>
                <div style="color: #666; font-size: 14px;">@${user.username}</div>
            </div>
            ${!isOwner ? `
                <button onclick="removeMember('${communityId}', '${user.id}')" style="
                    padding: 8px 16px;
                    background: #dc3545;
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 14px;
                    cursor: pointer;
                ">
                    Remover
                </button>
            ` : '<span style="color: #999; font-size: 12px;">Criador</span>'}
        `;
        
        container.appendChild(memberDiv);
    });
}

// ========== AUTOCOMPLETE PARA ADICIONAR MEMBROS ==========

let memberAutocompleteUsers = [];
let selectedMemberIndex = -1;

function setupUserSearch() {
    const searchInput = document.getElementById('searchUsers');
    if (!searchInput) return;
    
    // Carregar todos os usuários uma vez
    loadAllUsersForAutocomplete();
    
    searchInput.addEventListener('input', (e) => {
        const value = e.target.value;
        const cursorPos = e.target.selectionStart;
        
        // Detectar @ e extrair query
        const textBeforeCursor = value.substring(0, cursorPos);
        const atMatch = textBeforeCursor.match(/@(\w*)$/);
        
        if (atMatch) {
            const query = atMatch[1].toLowerCase();
            showMemberAutocomplete(query);
        } else {
            hideMemberAutocomplete();
        }
    });
    
    // Navegação com teclado
    searchInput.addEventListener('keydown', (e) => {
        const autocomplete = document.getElementById('memberAutocomplete');
        if (!autocomplete || autocomplete.style.display === 'none') return;
        
        const items = autocomplete.querySelectorAll('.mention-item');
        if (items.length === 0) return;
        
        if (e.key === 'ArrowDown') {
            e.preventDefault();
            selectedMemberIndex = Math.min(selectedMemberIndex + 1, items.length - 1);
            updateMemberSelection(items);
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            selectedMemberIndex = Math.max(selectedMemberIndex - 1, 0);
            updateMemberSelection(items);
        } else if (e.key === 'Enter' && selectedMemberIndex >= 0) {
            e.preventDefault();
            items[selectedMemberIndex].click();
        } else if (e.key === 'Escape') {
            hideMemberAutocomplete();
        }
    });
}

async function loadAllUsersForAutocomplete() {
    try {
        const { data: users, error } = await supabase
            .from('profiles')
            .select('id, name, username, avatar_url')
            .order('name');
        
        if (!error && users) {
            memberAutocompleteUsers = users;
            console.log(`✅ Carregados ${users.length} usuários para autocomplete`);
        }
    } catch (error) {
        console.error('❌ Erro ao carregar usuários:', error);
    }
}

async function showMemberAutocomplete(query) {
    const communityId = document.getElementById('communitySelect')?.value;
    if (!communityId) return;
    
    // Buscar membros atuais
    const { data: members } = await supabase
        .from('community_members')
        .select('user_id')
        .eq('community_id', communityId)
        .eq('is_active', true);
    
    const memberIds = members ? members.map(m => m.user_id) : [];
    
    // Filtrar usuários
    const filteredUsers = memberAutocompleteUsers.filter(user => {
        // Excluir usuário logado
        if (currentUser && user.id === currentUser.id) return false;
        
        // Excluir membros existentes
        if (memberIds.includes(user.id)) return false;
        
        // Filtrar por query
        const queryLower = query.toLowerCase();
        const nameLower = user.name.toLowerCase();
        const usernameLower = user.username.toLowerCase();
        
        return nameLower.includes(queryLower) || 
               usernameLower.includes(queryLower) ||
               usernameLower.startsWith(queryLower);
    }).slice(0, 5);
    
    if (filteredUsers.length === 0) {
        hideMemberAutocomplete();
        return;
    }
    
    // Criar/atualizar autocomplete
    let autocomplete = document.getElementById('memberAutocomplete');
    if (!autocomplete) {
        autocomplete = document.createElement('div');
        autocomplete.id = 'memberAutocomplete';
        autocomplete.className = 'mentions-autocomplete';
        const searchInput = document.getElementById('searchUsers');
        const rect = searchInput.getBoundingClientRect();
        const modalContent = searchInput.closest('.modal-content');
        const modalRect = modalContent ? modalContent.getBoundingClientRect() : { top: 0, left: 0 };
        
        // Posicionar relativo ao input, considerando scroll do modal
        autocomplete.style.cssText = `
            position: absolute;
            background: white;
            border: 1px solid #ddd;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            max-height: 200px;
            overflow-y: auto;
            z-index: 10001;
            margin-top: 5px;
            width: 100%;
        `;
        
        // Inserir logo após o input
        searchInput.parentElement.style.position = 'relative';
        searchInput.parentElement.appendChild(autocomplete);
    } else {
        // Autocomplete já existe, apenas atualizar conteúdo
    }
    
    autocomplete.innerHTML = filteredUsers.map((user, index) => `
        <div class="mention-item" data-user-id="${user.id}" data-username="${user.username}" data-index="${index}" style="
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px;
            cursor: pointer;
            border-bottom: 1px solid #f0f0f0;
        ">
            <img src="${user.avatar_url || 'https://via.placeholder.com/32'}" style="
                width: 32px;
                height: 32px;
                border-radius: 50%;
                object-fit: cover;
            ">
            <div style="flex: 1;">
                <div style="font-weight: 600; font-size: 14px;">${user.name}</div>
                <div style="color: #666; font-size: 12px;">@${user.username}</div>
            </div>
        </div>
    `).join('');
    
    autocomplete.style.display = 'block';
    selectedMemberIndex = -1;
    
    // Adicionar event listeners
    autocomplete.querySelectorAll('.mention-item').forEach(item => {
        item.addEventListener('click', () => {
            const userId = item.dataset.userId;
            const username = item.dataset.username;
            selectMemberToAdd(userId, username);
        });
        
        item.addEventListener('mouseenter', () => {
            item.style.background = '#f5f5f5';
        });
        
        item.addEventListener('mouseleave', () => {
            item.style.background = 'white';
        });
    });
}

function hideMemberAutocomplete() {
    const autocomplete = document.getElementById('memberAutocomplete');
    if (autocomplete) {
        autocomplete.style.display = 'none';
    }
    selectedMemberIndex = -1;
}

function updateMemberSelection(items) {
    items.forEach((item, index) => {
        if (index === selectedMemberIndex) {
            item.style.background = '#f5f5f5';
        } else {
            item.style.background = 'white';
        }
    });
}

async function selectMemberToAdd(userId, username) {
    const communityId = document.getElementById('communitySelect')?.value;
    if (!communityId) return;
    
    // Adicionar membro (com p_role para evitar ambiguidade)
    const { error } = await supabase.rpc('add_community_member', {
        p_community_id: communityId,
        p_user_id: userId,
        p_role: 'member'
    });
    
    if (error) {
        alert('❌ Erro: ' + error.message);
        return;
    }
    
    // Limpar input e esconder autocomplete
    const searchInput = document.getElementById('searchUsers');
    if (searchInput) {
        searchInput.value = '';
    }
    hideMemberAutocomplete();
    
    // Mostrar feedback
    alert(`✅ @${username} adicionado com sucesso!`);
    
    // Recarregar lista de membros
    loadCommunityMembers(communityId);
}

async function removeMember(communityId, userId) {
    if (!confirm('Tem certeza que deseja remover este membro?')) {
        return;
    }
    
    const { error } = await supabase
        .from('community_members')
        .update({ is_active: false })
        .eq('community_id', communityId)
        .eq('user_id', userId);
    
    if (error) {
        console.error('Erro ao remover membro:', error);
        alert('Erro ao remover membro: ' + error.message);
        return;
    }
    
    alert('✅ Membro removido com sucesso!');
    loadCommunityMembers(communityId);
}

// ========== POSTS ==========

async function loadCommunityPosts(communityId) {
    const { data: posts, error } = await supabase
        .from('posts')
        .select(`
            *,
            profiles:user_id (
                name,
                username,
                avatar_url
            )
        `)
        .eq('community_id', communityId)
        .order('created_at', { ascending: false })
        .limit(20);
    
    if (error) {
        console.error('Erro ao carregar posts:', error);
        return;
    }
    
    const container = document.getElementById('communityPosts');
    if (!container) return;
    
    container.innerHTML = '';
    
    if (!posts || posts.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #666;">Nenhum post ainda</p>';
        return;
    }
    
    posts.forEach(post => {
        const postDiv = document.createElement('div');
        postDiv.style.cssText = `
            padding: 15px;
            border-bottom: 1px solid #eee;
            background: white;
        `;
        
        const user = post.profiles;
        const typeEmojis = {
            'gratidao': '🙏',
            'memoria': '🧠',
            'conquista': '🏆',
            'inspiracao': '💡',
            'apoio': '🤝',
            'destacar': '⭐'
        };
        
        postDiv.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 10px;">
                <div style="display: flex; gap: 10px;">
                    <img src="${user?.avatar_url || 'https://via.placeholder.com/40'}" style="
                        width: 40px;
                        height: 40px;
                        border-radius: 50%;
                        object-fit: cover;
                    ">
                    <div>
                        <div style="font-weight: 600;">${user?.name || 'Usuário'}</div>
                        <div style="color: #666; font-size: 12px;">@${user?.username || 'usuario'}</div>
                    </div>
                </div>
                <button onclick="deletePost('${post.id}', '${communityId}')" style="
                    padding: 6px 12px;
                    background: #dc3545;
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 12px;
                    cursor: pointer;
                ">
                    Deletar
                </button>
            </div>
            <div style="margin-left: 50px;">
                <div style="margin-bottom: 5px;">
                    <span style="font-size: 20px;">${typeEmojis[post.type] || '📝'}</span>
                    <span style="font-weight: 600; margin-left: 5px;">${post.person_name || ''}</span>
                </div>
                <div style="color: #333;">${post.story_text}</div>
                ${post.photo_url ? `<img src="${post.photo_url}" style="max-width: 100%; border-radius: 8px; margin-top: 10px;">` : ''}
            </div>
        `;
        
        container.appendChild(postDiv);
    });
}

async function deletePost(postId, communityId) {
    if (!confirm('Tem certeza que deseja deletar este post?')) {
        return;
    }
    
    const { error } = await supabase
        .from('posts')
        .delete()
        .eq('id', postId);
    
    if (error) {
        console.error('Erro ao deletar post:', error);
        alert('Erro ao deletar post: ' + error.message);
        return;
    }
    
    alert('✅ Post deletado com sucesso!');
    loadCommunityPosts(communityId);
}

// ========== DELETAR COMUNIDADE ==========

async function deleteCommunity() {
    const communityId = document.getElementById('communitySelect').value;
    if (!communityId) return;
    
    if (!confirm('⚠️ ATENÇÃO: Deletar a comunidade irá remover TODOS os posts e membros. Esta ação não pode ser desfeita. Tem certeza?')) {
        return;
    }
    
    const { error } = await supabase
        .from('communities')
        .update({ is_active: false })
        .eq('id', communityId);
    
    if (error) {
        console.error('Erro ao deletar comunidade:', error);
        alert('Erro ao deletar comunidade: ' + error.message);
        return;
    }
    
    alert('✅ Comunidade deletada com sucesso!');
    closeManageCommunityModal();
    
    // Recarregar feeds se necessário
    if (typeof loadCommunityFeeds === 'function') {
        loadCommunityFeeds();
    }
}

// ========== INICIALIZAÇÃO ==========

function initCommunityManagement() {
    setupCommunitySelectListener();
    setupUserSearch();
    
    console.log('✅ Community Management inicializado');
}

// Exportar funções globalmente
window.openManageCommunityModal = openManageCommunityModal;
window.closeManageCommunityModal = closeManageCommunityModal;
window.switchManagementTab = switchManagementTab;
window.showCreateCommunityForm = showCreateCommunityForm;
window.hideCreateCommunityForm = hideCreateCommunityForm;
window.createCommunity = createCommunity;
window.updateCommunity = updateCommunity;
window.deleteCommunity = deleteCommunity;
window.openEmojiPicker = openEmojiPicker;
window.closeEmojiPicker = closeEmojiPicker;
window.selectEmoji = selectEmoji;
window.removeMember = removeMember;
window.deletePost = deletePost;
window.initCommunityManagement = initCommunityManagement;

console.log('✅ Módulo community_management.js carregado');

