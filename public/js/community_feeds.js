// ============================================
// COMMUNITY FEEDS
// Integra feeds de comunidades no dropdown existente
// ============================================

let userCommunities = [];

// Carregar comunidades do usuário e popular dropdowns
async function loadUserCommunities() {
    if (!currentUser || !currentUser.id) {
        console.log('⚠️ Usuário não logado');
        return;
    }

    try {
        // Buscar comunidades que o usuário é membro
        const { data: communities, error } = await supabase
            .from('community_members')
            .select(`
                community_id,
                communities (
                    id,
                    name,
                    slug,
                    emoji
                )
            `)
            .eq('user_id', currentUser.id)
            .eq('is_active', true);

        if (error) throw error;

        userCommunities = communities
            .map(c => c.communities)
            .filter(c => c !== null);

        console.log('✅ Comunidades carregadas:', userCommunities.length);

        // Popular dropdown do Feed
        populateFeedDropdown();

        // Popular dropdown do Destacar
        populateDestacarDropdown();

    } catch (error) {
        console.error('❌ Erro ao carregar comunidades:', error);
    }
}

// Popular dropdown do Feed (aba Início)
function populateFeedDropdown() {
    const dropdown = document.getElementById('feedFilterDropdown');
    if (!dropdown) return;

    // Remover opções de comunidades antigas
    const oldCommunityOptions = dropdown.querySelectorAll('[data-filter^="community-"]');
    oldCommunityOptions.forEach(opt => opt.remove());

    // Adicionar comunidades
    if (userCommunities.length > 0) {
        userCommunities.forEach(community => {
            const option = document.createElement('div');
            option.className = 'filter-option';
            option.setAttribute('data-filter', `community-${community.id}`);
            option.innerHTML = `<span>${community.emoji || '🏢'} ${community.name}</span>`;
            dropdown.appendChild(option);
        });

        console.log('✅ Dropdown do Feed atualizado com', userCommunities.length, 'comunidades');
    }
}

// Popular dropdown do Destacar
function populateDestacarDropdown() {
    const container = document.getElementById('destacarCommunityDropdownContainer');
    const select = document.getElementById('destacarCommunitySelect');

    if (!container || !select) return;

    // Limpar opções antigas (exceto a primeira)
    while (select.options.length > 1) {
        select.remove(1);
    }

    if (userCommunities.length > 0) {
        // Mostrar dropdown
        container.style.display = 'block';

        // Adicionar comunidades
        userCommunities.forEach(community => {
            const option = document.createElement('option');
            option.value = community.id;
            option.textContent = `${community.emoji || '🏢'} ${community.name}`;
            select.appendChild(option);
        });

        console.log('✅ Dropdown do Destacar atualizado com', userCommunities.length, 'comunidades');
    } else {
        // Esconder dropdown se não tem comunidades
        container.style.display = 'none';
    }
}

// Carregar feed de comunidade específica
async function loadCommunityFeed(communityId) {
    if (!currentUser || !currentUser.id) {
        console.log('⚠️ Usuário não logado');
        return;
    }

    try {
        console.log('📥 Carregando feed da comunidade:', communityId);

        // Buscar informações da comunidade
        const community = userCommunities.find(c => c.id === communityId);
        
        // Atualizar texto do botão Feed com emoji da comunidade
        const feedButton = document.querySelector('[data-tab="inicio"]');
        if (feedButton && community) {
            feedButton.textContent = `${community.emoji || '🏢'} Feed`;
        }

        const { data: posts, error } = await supabase.rpc('get_community_feed', {
            p_community_id: communityId,
            p_user_id: currentUser.id,
            p_limit: 20,
            p_offset: 0
        });

        if (error) throw error;

        console.log('✅ Posts da comunidade carregados:', posts.length);

        // Renderizar posts (usa função existente do index.html)
        const postsContainer = document.getElementById('postsContainer');
        if (postsContainer) {
            if (posts.length === 0) {
                const communityName = community ? community.name : 'esta comunidade';
                postsContainer.innerHTML = `
                    <div style="text-align: center; padding: 60px 20px; color: #666;">
                        <div style="font-size: 48px; margin-bottom: 16px;">📬</div>
                        <p style="font-size: 1.1rem; margin-bottom: 8px; color: #333;">Nenhum post em ${communityName} ainda</p>
                        <p style="font-size: 0.95rem; color: #999;">Seja o primeiro a postar!</p>
                    </div>
                `;
            } else {
                postsContainer.innerHTML = '';
                posts.forEach(post => {
                    if (typeof renderPost === 'function') {
                        renderPost(post);
                    }
                });
            }
        }

    } catch (error) {
        console.error('❌ Erro ao carregar feed da comunidade:', error);
        if (typeof showToast === 'function') {
            showToast('Erro ao carregar feed da comunidade');
        } else {
            alert('Erro ao carregar feed da comunidade');
        }
    }
}

// Interceptar mudança de filtro do Feed
function setupCommunityFeedFilter() {
    const dropdown = document.getElementById('feedFilterDropdown');
    if (!dropdown) return;

    // Usar event delegation para capturar cliques em opções de comunidade
    dropdown.addEventListener('click', async (e) => {
        const option = e.target.closest('.filter-option');
        if (!option) return;

        const filter = option.getAttribute('data-filter');

        // Se for filtro de comunidade
        if (filter && filter.startsWith('community-')) {
            const communityId = filter.replace('community-', '');

            // Marcar como ativo
            dropdown.querySelectorAll('.filter-option').forEach(opt => {
                opt.classList.remove('active');
            });
            option.classList.add('active');

            // Fechar dropdown
            dropdown.style.display = 'none';

            // Carregar feed da comunidade
            await loadCommunityFeed(communityId);

            // Salvar preferência
            localStorage.setItem('feedFilter', filter);
        }
    });

    console.log('✅ Filtro de comunidades configurado');
}

// Detectar comunidade selecionada ao criar post no Destacar
function getSelectedCommunityId() {
    const select = document.getElementById('destacarCommunitySelect');
    if (select && select.value) {
        return select.value;
    }
    return null;
}

// Inicializar ao carregar
if (typeof window !== 'undefined') {
    // Aguardar DOM e usuário logado
    document.addEventListener('DOMContentLoaded', () => {
        setupCommunityFeedFilter();
    });
}

// Exportar funções globalmente
window.loadUserCommunities = loadUserCommunities;
window.loadCommunityFeed = loadCommunityFeed;
window.getSelectedCommunityId = getSelectedCommunityId;

console.log('✅ community_feeds.js carregado');

