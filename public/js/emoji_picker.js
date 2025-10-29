/**
 * ============================================
 * MÓDULO: Emoji Picker
 * Descrição: Seletor de emojis para comunidades
 * Autor: HoloSpot Team
 * Data: 2024-10-29
 * ============================================
 */

// Lista de emojis populares (categorias)
const emojiList = {
    'Smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥲', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓'],
    'Animais': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🦝', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦢', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🦗', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🐠', '🐟', '🐡', '🐬', '🦈', '🐳', '🐋', '🐊', '🐆', '🐅'],
    'Comida': ['🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🥝', '🍑', '🥑', '🥥', '🥭', '🍅', '🍆', '🥒', '🥕', '🌽', '🌶️', '🥫', '🧄', '🧅', '🥔', '🍠', '🌰', '🥜', '🍯', '🥐', '🍞', '🥖', '🧀', '🥚', '🍳', '🥓', '🥞', '🍤', '🍗', '🍖', '🍕', '🌭', '🍔', '🍟', '🥙', '🌮', '🌯', '🥗', '🥘', '🥫', '🍝', '🍜', '🍲', '🍥', '🍣', '🍱', '🍛', '🍙', '🍚'],
    'Atividades': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓', '🏸', '🥅', '🏒', '🏑', '🏏', '🥍', '🏹', '🎣', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🪂', '🏋️', '🤼', '🤸', '🤺', '⛹️', '🤾', '🏌️', '🏇', '🧘', '🏊', '🤽', '🚣', '🧗', '🚵', '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🏵️', '🎗️', '🎫', '🎟️', '🎪', '🤹', '🎭', '🩰'],
    'Viagem': ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚛', '🚜', '🏍️', '🛵', '🚲', '🛴', '🛹', '🛺', '🚁', '🚟', '🚠', '🚡', '🛰️', '🚀', '🛸', '🛩️', '✈️', '🛫', '🛬', '🪂', '💺', '🚂', '🚆', '🚇', '🚊', '🚉', '🚝', '🚄', '🚅', '🚈', '🚞', '🚋', '🚃', '⛴️', '🛥️', '🚢', '⚓', '⛽', '🚧', '🚦', '🚥', '🏗️', '🏭', '🏰', '🏯', '🏟️', '🗼', '🏖️', '🏝️'],
    'Objetos': ['⌚', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️', '🗜️', '💽', '💾', '💿', '📀', '🧮', '📹', '🎥', '📷', '📸', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙️', '🎚️', '🎛️', '🧭', '⏱️', '⏲️', '⏰', '🕰️', '⌛', '⏳', '📡', '🔋', '🔌', '💡', '🔦', '🕯️', '🧯', '🛢️', '💸', '💵', '💴', '💶', '💷', '💰', '💳', '🧾', '💎', '⚖️', '🧰', '🔧', '🔨', '⚒️', '🛠️', '⛏️'],
    'Símbolos': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳', '✴️', '🆚', '💮', '🉐', '㊙️', '㊗️', '✅', '❌', '⭕', '🛑', '⛔', '📛'],
    'Empresas': ['🏢', '🏭', '🏛️', '🏚️', '🏗️', '🏪', '🏦', '🏥', '🏣', '🏤', '🏩', '🏫', '🏬', '🏯', '🏰', '💼', '📊', '📈', '📉', '💹', '💰', '💸', '💵', '💴', '💶', '💷', '💳', '🧾', '💱', '💲', '⚖️', '🧱', '🪜', '🔧', '🔨', '⚒️', '🛠️', '⛏️', '🪛', '🔩', '⚙️', '🧰', '🧲', '📦', '📥', '📤', '📫', '📪', '📨', '📩', '📧', '💌', '📮', '📯', '📬', '📭', '📡', '📰', '📅', '📆', '🗓️']
};

let currentEmojiTarget = null;

function openEmojiPicker(targetInputId) {
    currentEmojiTarget = targetInputId;
    
    const modal = document.getElementById('emojiPickerModal');
    if (modal) {
        modal.style.display = 'flex';
        renderEmojiGrid();
    } else {
        console.error('Modal emojiPickerModal não encontrado');
    }
}

function closeEmojiPicker() {
    const modal = document.getElementById('emojiPickerModal');
    if (modal) {
        modal.style.display = 'none';
    }
    
    const searchInput = document.getElementById('emojiSearch');
    if (searchInput) {
        searchInput.value = '';
    }
    
    currentEmojiTarget = null;
}

function renderEmojiGrid(filter = '') {
    const grid = document.getElementById('emojiGrid');
    if (!grid) {
        console.error('Elemento emojiGrid não encontrado');
        return;
    }
    
    grid.innerHTML = '';
    
    Object.entries(emojiList).forEach(([category, emojis]) => {
        // Filtrar emojis se houver busca
        let filteredEmojis = emojis;
        if (filter) {
            // Busca simples por categoria
            if (!category.toLowerCase().includes(filter.toLowerCase())) {
                return;
            }
        }
        
        if (filteredEmojis.length === 0) return;
        
        // Título da categoria
        const categoryTitle = document.createElement('div');
        categoryTitle.style.cssText = `
            grid-column: 1 / -1;
            font-weight: 600;
            font-size: 12px;
            color: #666;
            margin-top: 10px;
            margin-bottom: 5px;
        `;
        categoryTitle.textContent = category;
        grid.appendChild(categoryTitle);
        
        // Emojis
        filteredEmojis.forEach(emoji => {
            const button = document.createElement('button');
            button.type = 'button';
            button.textContent = emoji;
            button.style.cssText = `
                width: 40px;
                height: 40px;
                font-size: 24px;
                border: 1px solid #eee;
                border-radius: 6px;
                background: white;
                cursor: pointer;
                transition: all 0.2s;
            `;
            
            button.addEventListener('mouseenter', () => {
                button.style.background = '#f0f0f0';
                button.style.transform = 'scale(1.2)';
            });
            
            button.addEventListener('mouseleave', () => {
                button.style.background = 'white';
                button.style.transform = 'scale(1)';
            });
            
            button.addEventListener('click', () => {
                selectEmoji(emoji);
            });
            
            grid.appendChild(button);
        });
    });
}

function selectEmoji(emoji) {
    if (currentEmojiTarget) {
        const input = document.getElementById(currentEmojiTarget);
        if (input) {
            input.value = emoji;
        }
    }
    closeEmojiPicker();
}

// Busca de emoji
function setupEmojiSearch() {
    const searchInput = document.getElementById('emojiSearch');
    if (!searchInput) return;
    
    searchInput.addEventListener('input', (e) => {
        renderEmojiGrid(e.target.value);
    });
}

// Fechar modal ao clicar fora
function setupEmojiModalClickOutside() {
    const modal = document.getElementById('emojiPickerModal');
    if (!modal) return;
    
    modal.addEventListener('click', (e) => {
        if (e.target.id === 'emojiPickerModal') {
            closeEmojiPicker();
        }
    });
}

// Inicializar emoji picker
function initEmojiPicker() {
    setupEmojiSearch();
    setupEmojiModalClickOutside();
    
    console.log('✅ Emoji Picker inicializado');
}

// Exportar funções globalmente
window.openEmojiPicker = openEmojiPicker;
window.closeEmojiPicker = closeEmojiPicker;
window.initEmojiPicker = initEmojiPicker;

console.log('✅ Módulo emoji_picker.js carregado');

