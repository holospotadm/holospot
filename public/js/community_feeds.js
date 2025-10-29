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
                postsContainer.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-state-icon">📭</div>
                        <p>Nenhum post nesta comunidade ainda.</p>
                        <p style="font-size: 0.9rem; color: #666;">Seja o primeiro a postar!</p>
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
        showToast('Erro ao carregar feed da comunidade');
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

