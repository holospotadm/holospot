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
    
    // Preencher formulário de edição
    const form = document.getElementById('editCommunityForm');
    if (form) {
        form.community_id.value = community.id;
        form.emoji.value = community.emoji || '🏢';
        form.name.value = community.name;
        form.description.value = community.description || '';
        form.logo_url.value = community.logo_url || '';
    }
    
    // Carregar membros
    loadCommunityMembers(community.id);
    
    // Carregar posts
    loadCommunityPosts(community.id);
    
    // Mostrar tab de edição
    switchManagementTab('edit');
}

// Trocar tab de gerenciamento
function switchManagementTab(tab) {
    // Atualizar botões
    document.querySelectorAll('.management-tab').forEach(btn => {
        btn.classList.remove('active');
        btn.style.borderBottom = '3px solid transparent';
    });
    
    const activeBtn = document.querySelector(`[data-tab="${tab}"]`);
    if (activeBtn) {
        activeBtn.classList.add('active');
        activeBtn.style.borderBottom = '3px solid #667eea';
    }
    
    // Mostrar/esconder conteúdo
    document.querySelectorAll('.management-tab-content').forEach(content => {
        content.style.display = 'none';
    });
    
    const tabContent = document.getElementById(`${tab}Tab`);
    if (tabContent) {
        tabContent.style.display = 'block';
    }
}

// Mostrar/esconder formulário de criar comunidade
function showCreateCommunityForm() {
    const form = document.getElementById('createCommunityForm');
    if (form) {
        form.style.display = 'block';
    }
    
    const select = document.getElementById('communitySelect');
    if (select) {
        select.value = '';
    }
    
    const info = document.getElementById('communityInfo');
    if (info) {
        info.style.display = 'none';
    }
}

function hideCreateCommunityForm() {
    const form = document.getElementById('createCommunityForm');
    if (form) {
        form.style.display = 'none';
    }
    
    const newForm = document.getElementById('newCommunityForm');
    if (newForm) {
        newForm.reset();
    }
    
    const emojiInput = document.getElementById('newCommunityEmoji');
    if (emojiInput) {
        emojiInput.value = '🏢';
    }
}

// Criar nova comunidade
function setupNewCommunityForm() {
    const form = document.getElementById('newCommunityForm');
    if (!form) return;
    
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        if (!currentUser || !currentUser.id) {
            alert('❌ Você precisa estar logado');
            return;
        }
        
        const formData = new FormData(e.target);
        const slug = formData.get('slug');
        
        // Validar slug único
        const { data: existing, error: checkError } = await supabase
            .from('communities')
            .select('id')
            .eq('slug', slug)
            .maybeSingle();
        
        if (checkError) {
            alert('❌ Erro ao validar slug: ' + checkError.message);
            return;
        }
        
        if (existing) {
            alert('❌ Este slug já está em uso! Escolha outro.');
            return;
        }
        
        const { data: communityId, error } = await supabase.rpc('create_community', {
            p_name: formData.get('name'),
            p_slug: slug,
            p_description: formData.get('description') || null,
            p_emoji: formData.get('emoji') || '🏢',
            p_owner_id: currentUser.id
        });
        
        if (error) {
            alert('❌ Erro ao criar comunidade: ' + error.message);
            return;
        }
        
        alert('✅ Comunidade criada com sucesso!');
        
        // Resetar formulário
        e.target.reset();
        
        hideCreateCommunityForm();
        
        // Recarregar lista de comunidades
        await loadOwnedCommunities();
        
        // Atualizar tabs de feed
        if (typeof loadUserCommunities === 'function') {
            await loadUserCommunities();
        }
        
        // Selecionar nova comunidade
        const select = document.getElementById('communitySelect');
        if (select) {
            select.value = communityId;
            select.dispatchEvent(new Event('change'));
        }
    });
}

// Editar comunidade
function setupEditCommunityForm() {
    const form = document.getElementById('editCommunityForm');
    if (!form) return;
    
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        
        const { error } = await supabase.rpc('update_community', {
            p_community_id: formData.get('community_id'),
            p_name: formData.get('name'),
            p_slug: null,
            p_description: formData.get('description') || null,
            p_emoji: formData.get('emoji') || '🏢',
            p_logo_url: null
        });
        
        if (error) {
            alert('❌ Erro ao atualizar comunidade: ' + error.message);
            return;
        }
        
        alert('✅ Comunidade atualizada com sucesso!');
        
        // Recarregar lista
        await loadOwnedCommunities();
        
        // Atualizar tabs de feed
        if (typeof loadUserCommunities === 'function') {
            await loadUserCommunities();
        }
    });
}

// Carregar membros da comunidade
async function loadCommunityMembers(communityId) {
    const { data: members, error } = await supabase
        .from('community_members')
        .select(`
            user_id,
            role,
            joined_at,
            profiles (
                name,
                username,
                avatar_url
            )
        `)
        .eq('community_id', communityId)
        .eq('is_active', true)
        .order('joined_at', { ascending: false });
    
    if (error) {
        console.error('Erro ao carregar membros:', error);
        return;
    }
    
    const membersDiv = document.getElementById('currentMembers');
    if (!membersDiv) return;
    
    membersDiv.innerHTML = '';
    
    if (members.length === 0) {
        membersDiv.innerHTML = '<p style="text-align: center; color: #666;">Nenhum membro ainda</p>';
        return;
    }
    
    members.forEach(member => {
        const memberDiv = document.createElement('div');
        memberDiv.style.cssText = `
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px;
            border-bottom: 1px solid #eee;
        `;
        
        const isOwner = member.role === 'owner';
        
        memberDiv.innerHTML = `
            <img src="${member.profiles.avatar_url || 'https://via.placeholder.com/40'}" style="
                width: 40px;
                height: 40px;
                border-radius: 50%;
                object-fit: cover;
            ">
            <div style="flex: 1;">
                <div style="font-weight: 600;">
                    ${member.profiles.name}
                    ${isOwner ? '<span style="background: #667eea; color: white; padding: 2px 8px; border-radius: 4px; font-size: 12px; margin-left: 8px;">OWNER</span>' : ''}
                </div>
                <div style="color: #666; font-size: 14px;">@${member.profiles.username}</div>
            </div>
            ${!isOwner ? `
                <button onclick="removeMember('${communityId}', '${member.user_id}')" style="
                    padding: 8px 16px;
                    background: #ff4444;
                    color: white;
                    border: none;
                    border-radius: 6px;
                    font-size: 14px;
                    cursor: pointer;
                ">
                    Remover
                </button>
            ` : ''}
        `;
        
        membersDiv.appendChild(memberDiv);
    });
}

// Buscar usuários para adicionar
let communitySearchTimeout;
function setupUserSearch() {
    const searchInput = document.getElementById('searchUsers');
    if (!searchInput) return;
    
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.trim();
        
        if (query.length < 2) {
            const resultsDiv = document.getElementById('searchResults');
            if (resultsDiv) {
                resultsDiv.innerHTML = '';
            }
            return;
        }
        
        clearTimeout(communitySearchTimeout);
        communitySearchTimeout = setTimeout(() => searchUsers(query), 300);
    });
}

async function searchUsers(query) {
    const communityId = document.getElementById('communitySelect')?.value;
    if (!communityId) return;
    
    const { data: users, error } = await supabase
        .from('profiles')
        .select('id, name, username, avatar_url')
        .or(`name.ilike.%${query}%,username.ilike.%${query}%`)
        .limit(10);
    
    if (error) {
        console.error('Erro ao buscar usuários:', error);
        return;
    }
    
    // Filtrar usuários que já são membros
    const { data: members } = await supabase
        .from('community_members')
        .select('user_id')
        .eq('community_id', communityId)
        .eq('is_active', true);
    
    const memberIds = members ? members.map(m => m.user_id) : [];
    const availableUsers = users.filter(u => !memberIds.includes(u.id));
    
    const resultsDiv = document.getElementById('searchResults');
    if (!resultsDiv) return;
    
    resultsDiv.innerHTML = '';
    
    if (availableUsers.length === 0) {
        resultsDiv.innerHTML = '<p style="text-align: center; color: #666;">Nenhum usuário encontrado</p>';
        return;
    }
    
    availableUsers.forEach(user => {
        const userDiv = document.createElement('div');
        userDiv.style.cssText = `
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px;
            border-bottom: 1px solid #eee;
        `;
        
        userDiv.innerHTML = `
            <img src="${user.avatar_url || 'https://via.placeholder.com/40'}" style="
                width: 40px;
                height: 40px;
                border-radius: 50%;
                object-fit: cover;
            ">
            <div style="flex: 1;">
                <div style="font-weight: 600;">${user.name}</div>
                <div style="color: #666; font-size: 14px;">@${user.username}</div>
            </div>
            <button onclick="addMember('${communityId}', '${user.id}')" style="
                padding: 8px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 14px;
                cursor: pointer;
            ">
                Adicionar
            </button>
        `;
        
        resultsDiv.appendChild(userDiv);
    });
}

async function addMember(communityId, userId) {
    const { error } = await supabase.rpc('add_community_member', {
        p_community_id: communityId,
        p_user_id: userId
    });
    
    if (error) {
        alert('❌ Erro: ' + error.message);
        return;
    }
    
    alert('✅ Membro adicionado com sucesso!');
    
    // Recarregar listas
    const searchInput = document.getElementById('searchUsers');
    if (searchInput && searchInput.value) {
        searchUsers(searchInput.value);
    }
    loadCommunityMembers(communityId);
}

async function removeMember(communityId, userId) {
    if (!confirm('Tem certeza que deseja remover este membro?')) {
        return;
    }
    
    const { error } = await supabase.rpc('remove_community_member', {
        p_community_id: communityId,
        p_user_id: userId
    });
    
    if (error) {
        alert('❌ Erro: ' + error.message);
        return;
    }
    
    alert('✅ Membro removido com sucesso!');
    loadCommunityMembers(communityId);
}

// Carregar posts da comunidade
async function loadCommunityPosts(communityId) {
    const { data: posts, error } = await supabase
        .from('posts')
        .select(`
            *,
            profiles (
                name,
                username,
                avatar_url
            )
        `)
        .eq('community_id', communityId)
        .order('created_at', { ascending: false })
        .limit(50);
    
    if (error) {
        console.error('Erro ao carregar posts:', error);
        return;
    }
    
    const postsDiv = document.getElementById('communityPosts');
    if (!postsDiv) return;
    
    postsDiv.innerHTML = '';
    
    if (posts.length === 0) {
        postsDiv.innerHTML = '<p style="text-align: center; color: #666;">Nenhum post ainda</p>';
        return;
    }
    
    posts.forEach(post => {
        const postDiv = document.createElement('div');
        postDiv.style.cssText = `
            padding: 15px;
            border-bottom: 1px solid #eee;
            background: white;
            margin-bottom: 10px;
            border-radius: 8px;
        `;
        
        postDiv.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                <img src="${post.profiles.avatar_url || 'https://via.placeholder.com/40'}" style="
                    width: 40px;
                    height: 40px;
                    border-radius: 50%;
                    object-fit: cover;
                ">
                <div>
                    <div style="font-weight: 600;">${post.profiles.name}</div>
                    <div style="color: #666; font-size: 12px;">@${post.profiles.username}</div>
                </div>
            </div>
            
            <div style="margin-bottom: 10px;">
                <strong>🎉 ${post.celebrated_person_name || post.person_name}</strong>
            </div>
            
            <div style="color: #333; margin-bottom: 10px;">
                ${post.content}
            </div>
            
            ${post.image_url ? `
                <img src="${post.image_url}" style="
                    width: 100%;
                    max-height: 300px;
                    object-fit: cover;
                    border-radius: 8px;
                    margin-bottom: 10px;
                ">
            ` : ''}
            
            <div style="display: flex; gap: 10px; color: #666; font-size: 14px; margin-bottom: 10px;">
                <span>❤️ ${post.likes_count} holofotes</span>
                <span>💬 ${post.comments_count} comentários</span>
            </div>
            
            <button onclick="deletePost('${post.id}', '${communityId}')" style="
                padding: 6px 12px;
                background: #ff4444;
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 12px;
                cursor: pointer;
            ">
                🗑️ Remover Post
            </button>
        `;
        
        postsDiv.appendChild(postDiv);
    });
}

async function deletePost(postId, communityId) {
    if (!confirm('Tem certeza que deseja remover este post?')) {
        return;
    }
    
    const { error } = await supabase
        .from('posts')
        .delete()
        .eq('id', postId);
    
    if (error) {
        alert('❌ Erro ao remover post: ' + error.message);
        return;
    }
    
    alert('✅ Post removido com sucesso!');
    loadCommunityPosts(communityId);
}

// Fechar modal ao clicar fora
function setupModalClickOutside() {
    const modal = document.getElementById('manageCommunityModal');
    if (!modal) return;
    
    modal.addEventListener('click', (e) => {
        if (e.target.id === 'manageCommunityModal') {
            closeManageCommunityModal();
        }
    });
}

// Inicializar todos os listeners
function initCommunityManagement() {
    setupCommunitySelectListener();
    setupNewCommunityForm();
    setupEditCommunityForm();
    setupUserSearch();
    setupModalClickOutside();
    
    console.log('✅ Community Management inicializado');
}

// Exportar funções globalmente
window.openManageCommunityModal = openManageCommunityModal;
window.closeManageCommunityModal = closeManageCommunityModal;
window.switchManagementTab = switchManagementTab;
window.showCreateCommunityForm = showCreateCommunityForm;
window.hideCreateCommunityForm = hideCreateCommunityForm;
window.addMember = addMember;
window.removeMember = removeMember;
window.deletePost = deletePost;
window.initCommunityManagement = initCommunityManagement;

console.log('✅ Módulo community_management.js carregado');




// Deletar comunidade
async function deleteCommunity() {
    const select = document.getElementById('communitySelect');
    if (!select || !select.value) {
        alert('❌ Nenhuma comunidade selecionada');
        return;
    }
    
    const communityId = select.value;
    const communityName = select.options[select.selectedIndex].text;
    
    if (!confirm(`⚠️ Tem certeza que deseja deletar a comunidade "${communityName}"?\n\nEsta ação não pode ser desfeita!`)) {
        return;
    }
    
    const { error } = await supabase
        .from('communities')
        .delete()
        .eq('id', communityId);
    
    if (error) {
        alert('❌ Erro ao deletar comunidade: ' + error.message);
        return;
    }
    
    alert('✅ Comunidade deletada com sucesso!');
    
    // Limpar seleção
    select.value = '';
    document.getElementById('communityInfo').style.display = 'none';
    
    // Recarregar lista
    await loadOwnedCommunities();
    
    // Atualizar tabs de feed
    if (typeof loadUserCommunities === 'function') {
        await loadUserCommunities();
    }
}

