/**
 * ============================================
 * MÓDULO: Community Feeds
 * Descrição: Gerencia tabs dinâmicas de feeds de comunidades
 * Autor: HoloSpot Team
 * Data: 2024-10-29
 * ============================================
 */

// Carregar comunidades do usuário e criar tabs
async function loadUserCommunities() {
    if (!currentUser || !currentUser.id) {
        console.log('Usuário não autenticado');
        return;
    }

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
    currentUser.communities = memberships || [];
    
    // Adicionar tabs de comunidades
    const feedTabs = document.getElementById('feedTabs');
    
    if (!feedTabs) {
        console.error('Elemento feedTabs não encontrado');
        return;
    }
    
    // Remover tabs antigas de comunidades (manter apenas Para Você e Seguindo)
    const existingTabs = feedTabs.querySelectorAll('.tab');
    existingTabs.forEach(tab => {
        if (tab.dataset.feed && tab.dataset.feed.startsWith('community-')) {
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
    } else {
        // Se não encontrar, ativar "Para Você"
        const defaultTab = feedTabs.querySelector('[data-feed="for-you"]');
        if (defaultTab) {
            defaultTab.click();
        }
    }
}

// Carregar feed da comunidade
async function loadCommunityFeed(communityId) {
    if (!currentUser || !currentUser.id) {
        console.error('Usuário não autenticado');
        return;
    }

    localStorage.setItem('activeFeed', `community-${communityId}`);
    
    // Mostrar loading
    const postsContainer = document.getElementById('postsContainer');
    if (postsContainer) {
        postsContainer.innerHTML = '<div style="text-align: center; padding: 40px; color: #666;">Carregando...</div>';
    }
    
    const { data: posts, error } = await supabase.rpc('get_community_feed', {
        p_community_id: communityId,
        p_user_id: currentUser.id,
        p_limit: 20,
        p_offset: 0
    });
    
    if (error) {
        console.error('Erro ao carregar feed da comunidade:', error);
        if (postsContainer) {
            postsContainer.innerHTML = '<div style="text-align: center; padding: 40px; color: #ff4444;">❌ Erro ao carregar feed da comunidade</div>';
        }
        return;
    }
    
    // Processar dados dos usuários
    if (typeof processPostsUserData === 'function') {
        await processPostsUserData(posts);
    }
    
    // Renderizar posts
    if (typeof renderPosts === 'function') {
        renderPosts(posts);
    } else {
        console.error('Função renderPosts não encontrada');
    }
}

// Modificar event listeners das tabs existentes
function setupFeedTabs() {
    const feedTabs = document.getElementById('feedTabs');
    if (!feedTabs) return;

    document.querySelectorAll('.tab').forEach(tab => {
        // Remover listeners antigos
        const newTab = tab.cloneNode(true);
        tab.parentNode.replaceChild(newTab, tab);
        
        newTab.addEventListener('click', () => {
            const feed = newTab.dataset.feed;
            
            if (!feed) return;
            
            localStorage.setItem('activeFeed', feed);
            
            // Remover active de todas
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            newTab.classList.add('active');
            
            if (feed === 'for-you' || feed === 'following') {
                // Carregar feed global (função existente)
                if (typeof loadPosts === 'function') {
                    loadPosts();
                }
            } else if (feed.startsWith('community-')) {
                // Carregar feed de comunidade
                const communityId = newTab.dataset.communityId;
                if (communityId) {
                    loadCommunityFeed(communityId);
                }
            }
        });
    });
}

// Detectar feed ativo ao criar post
function getActiveCommunityId() {
    const activeFeed = localStorage.getItem('activeFeed');
    
    if (activeFeed && activeFeed.startsWith('community-')) {
        const activeTab = document.querySelector(`[data-feed="${activeFeed}"]`);
        if (activeTab && activeTab.dataset.communityId) {
            return activeTab.dataset.communityId;
        }
    }
    
    return null;
}

// Exportar funções globalmente
window.loadUserCommunities = loadUserCommunities;
window.loadCommunityFeed = loadCommunityFeed;
window.setupFeedTabs = setupFeedTabs;
window.getActiveCommunityId = getActiveCommunityId;

console.log('✅ Módulo community_feeds.js carregado');

