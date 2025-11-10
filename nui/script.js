const state = {
    items: [],
    itemLookup: {},
    currency: { symbol: '💎', name: 'Ghost Coin' },
    layout: { sections: [] },
    selectedItem: null,
    wallet: 0,
    activity: [],
    crateAnimation: null
};

const app = document.getElementById('app');
const sectionsRoot = document.getElementById('sectionsRoot');
const walletValue = document.getElementById('walletValue');
const activityLog = document.getElementById('activityLog');
const modal = document.getElementById('modal');
const modalTitle = document.getElementById('modalTitle');
const modalDescription = document.getElementById('modalDescription');
const modalFeedback = document.getElementById('modalFeedback');
const confirmPurchase = document.getElementById('confirmPurchase');
const cancelPurchase = document.getElementById('cancelPurchase');
const heroBadge = document.getElementById('heroBadge');
const heroTitle = document.getElementById('heroTitle');
const heroSubtitle = document.getElementById('heroSubtitle');
const heroCountdown = document.getElementById('heroCountdown');
const heroPrimary = document.getElementById('heroPrimary');
const heroSecondary = document.getElementById('heroSecondary');
const heroFeatured = document.getElementById('heroFeatured');
const crateOverlay = document.getElementById('crateOverlay');
const crateTitle = document.getElementById('crateTitle');
const crateTrack = document.getElementById('crateTrack');
const crateReel = document.getElementById('crateReel');
const crateSummary = document.getElementById('crateSummary');
const crateRewardIcon = document.getElementById('crateRewardIcon');
const crateRewardLabel = document.getElementById('crateRewardLabel');
const crateRewardRarity = document.getElementById('crateRewardRarity');
const crateContinue = document.getElementById('crateContinue');
const crateClose = document.getElementById('crateClose');

function formatPrice(amount) {
    const numeric = typeof amount === 'number' ? amount : Number(amount) || 0;
    const formatted = numeric.toLocaleString('pl-PL');
    return `${state.currency.symbol || '💎'} ${formatted}`;
}

function formatTypeLabel(type) {
    const labels = {
        item: 'Przedmiot',
        money: 'Gotówka',
        group: 'Grupa',
        vehicle: 'Pojazd',
        weapon: 'Broń',
        crate: 'Skrzynka'
    };
    return labels[type] || type || '';
}

function setWallet(amount) {
    state.wallet = typeof amount === 'number' ? amount : 0;
    if (walletValue) {
        walletValue.textContent = formatPrice(state.wallet);
        if (state.currency && state.currency.color) {
            walletValue.style.color = state.currency.color;
        } else {
            walletValue.style.color = '';
        }
    }
}

function safeArray(value) {
    return Array.isArray(value) ? value : [];
}

function filterItems(filter) {
    if (!filter) {
        return state.items.slice();
    }

    const ids = safeArray(filter.ids);
    const excludeIds = safeArray(filter.excludeIds);

    return state.items.filter((item) => {
        if (!item) {
            return false;
        }

        if (ids.length > 0 && !ids.includes(item.id)) {
            return false;
        }

        if (excludeIds.length > 0 && excludeIds.includes(item.id)) {
            return false;
        }

        if (filter.category && item.category !== filter.category) {
            return false;
        }

        if (filter.rewardType && (!item.rewardData || item.rewardData.type !== filter.rewardType)) {
            return false;
        }

        return true;
    }).slice(0, filter.limit || undefined);
}

function createItemCard(item, variant) {
    const card = document.createElement('article');
    const cardVariant = variant || 'grid';
    card.className = `item-card item-card--${cardVariant}`;
    card.dataset.itemId = item.id;

    const highlight = item.rewardData && item.rewardData.highlight;
    if (highlight) {
        card.classList.add('item-card--accented');
        card.style.setProperty('--item-accent', highlight);
        if (typeof highlight === 'string' && highlight.startsWith('#') && highlight.length === 7) {
            card.style.setProperty('--item-accent-soft', `${highlight}55`);
        }
    }

    const typeLabel = formatTypeLabel(item.rewardData && item.rewardData.type);

    card.innerHTML = `
        <div class="card-header">
            <span class="card-icon">${item.icon || '💎'}</span>
            <div class="card-meta">
                <h3 class="card-title">${item.label}</h3>
                <span class="card-type">${typeLabel}</span>
            </div>
        </div>
        <p class="card-description">${item.description}</p>
        <div class="card-footer">
            <span class="card-price">${formatPrice(item.price)}</span>
            <button class="btn ghost card-action">Kup</button>
        </div>
    `;

    card.addEventListener('click', () => openModal(item));

    const button = card.querySelector('.card-action');
    if (button) {
        button.addEventListener('click', (event) => {
            event.stopPropagation();
            openModal(item);
        });
    }

    return card;
}

function renderHeroFeatured() {
    if (!heroFeatured) {
        return;
    }

    heroFeatured.innerHTML = '';
    const hero = state.layout && state.layout.hero;
    if (!hero || !Array.isArray(hero.featuredItems) || hero.featuredItems.length === 0) {
        heroFeatured.classList.add('hidden');
        return;
    }

    heroFeatured.classList.remove('hidden');

    hero.featuredItems.forEach((id) => {
        const item = state.itemLookup[id];
        if (!item) {
            return;
        }

        const card = createItemCard(item, 'hero');
        heroFeatured.appendChild(card);
    });
}

function applyHeroLayout() {
    const hero = state.layout && state.layout.hero ? state.layout.hero : {};

    if (heroBadge) {
        heroBadge.textContent = hero.badge || 'Ghost Market';
    }

    if (heroTitle) {
        heroTitle.textContent = hero.title || 'Ghost Market';
    }

    if (heroSubtitle) {
        heroSubtitle.textContent = hero.subtitle || '';
    }

    if (heroCountdown) {
        heroCountdown.textContent = hero.countdown || '';
    }

    if (heroPrimary) {
        if (hero.primaryCTA) {
            heroPrimary.textContent = hero.primaryCTA.label || 'Zobacz ofertę';
            heroPrimary.dataset.target = hero.primaryCTA.target || '';
            heroPrimary.classList.remove('hidden');
        } else {
            heroPrimary.classList.add('hidden');
            heroPrimary.dataset.target = '';
        }
    }

    if (heroSecondary) {
        if (hero.secondaryCTA) {
            heroSecondary.textContent = hero.secondaryCTA.label || 'Więcej';
            heroSecondary.dataset.target = hero.secondaryCTA.target || '';
            heroSecondary.classList.remove('hidden');
        } else {
            heroSecondary.classList.add('hidden');
            heroSecondary.dataset.target = '';
        }
    }

    renderHeroFeatured();
}

function renderSections() {
    if (!sectionsRoot) {
        return;
    }

    sectionsRoot.innerHTML = '';
    const sections = Array.isArray(state.layout && state.layout.sections)
        ? state.layout.sections
        : [];

    sections.forEach((sectionConfig) => {
        const section = document.createElement('section');
        section.className = 'catalog-section';
        if (sectionConfig.id) {
            section.dataset.section = sectionConfig.id;
        }

        const header = document.createElement('header');
        const title = document.createElement('h2');
        title.textContent = sectionConfig.title || 'Oferta';
        header.appendChild(title);

        if (sectionConfig.subtitle) {
            const subtitle = document.createElement('p');
            subtitle.className = 'section-subtitle';
            subtitle.textContent = sectionConfig.subtitle;
            header.appendChild(subtitle);
        }

        section.appendChild(header);

        const grid = document.createElement('div');
        grid.className = 'card-grid';

        switch (sectionConfig.variant) {
            case 'highlight':
                grid.classList.add('card-grid--rail');
                break;
            case 'feature':
                grid.classList.add('card-grid--feature');
                break;
            case 'list':
                grid.classList.add('card-grid--list');
                break;
            default:
                break;
        }

        const items = filterItems(sectionConfig.filter);

        if (!items.length) {
            const placeholder = document.createElement('p');
            placeholder.className = 'placeholder';
            placeholder.textContent = 'Brak produktów w tej sekcji.';
            grid.appendChild(placeholder);
        } else {
            items.forEach((item) => {
                let variant = 'grid';
                if (sectionConfig.variant === 'highlight') {
                    variant = 'highlight';
                } else if (sectionConfig.variant === 'feature') {
                    variant = 'feature';
                } else if (sectionConfig.variant === 'list') {
                    variant = 'list';
                }

                const card = createItemCard(item, variant);
                grid.appendChild(card);
            });
        }

        section.appendChild(grid);
        sectionsRoot.appendChild(section);
    });
}

function openModal(item) {
    state.selectedItem = item;
    if (modalTitle) {
        modalTitle.textContent = 'Potwierdzenie zakupu';
    }
    if (modalDescription) {
        modalDescription.textContent = `Czy na pewno kupić ${item.label} za ${formatPrice(item.price)}?`;
    }
    if (modalFeedback) {
        modalFeedback.textContent = '';
    }
    if (modal) {
        modal.classList.remove('hidden');
    }
}

function closeModal() {
    state.selectedItem = null;
    if (modal) {
        modal.classList.add('hidden');
    }
    if (modalFeedback) {
        modalFeedback.textContent = '';
    }
}

function trimActivityLog() {
    const limit = 6;
    if (state.activity.length > limit) {
        state.activity = state.activity.slice(-limit);
    }
}

function addActivityEntry(message, success) {
    if (!activityLog) {
        return;
    }

    const entry = {
        message,
        success,
        timestamp: new Date().toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' })
    };

    state.activity.push(entry);
    trimActivityLog();

    activityLog.innerHTML = '';

    state.activity.forEach((item) => {
        const element = document.createElement('div');
        element.className = 'activity-entry';
        if (item.success === true) {
            element.classList.add('success');
        } else if (item.success === false) {
            element.classList.add('error');
        }

        const label = document.createElement('span');
        label.textContent = item.message;

        const time = document.createElement('span');
        time.textContent = item.timestamp;

        element.appendChild(label);
        element.appendChild(time);
        activityLog.appendChild(element);
    });
}

function resetActivityPlaceholder() {
    if (!activityLog) {
        return;
    }

    if (!activityLog.querySelector('.placeholder') && state.activity.length === 0) {
        const placeholder = document.createElement('p');
        placeholder.className = 'placeholder';
        placeholder.textContent = 'Brak ostatnich zakupów. Dokonaj transakcji, aby pojawiły się wpisy.';
        activityLog.appendChild(placeholder);
    }
}

function resetCrateOverlay() {
    if (!crateOverlay) {
        return;
    }

    if (state.crateAnimation) {
        state.crateAnimation.cancel();
        state.crateAnimation = null;
    }

    crateOverlay.classList.add('hidden');
    crateSummary.classList.remove('visible');
    crateSummary.style.boxShadow = '';
    crateSummary.style.borderColor = '';
    crateRewardRarity.style.color = '';
    crateTrack.innerHTML = '';
}

function closeCrateOverlay() {
    const rewardLabel = crateRewardLabel ? crateRewardLabel.textContent : '';
    const summaryVisible = crateSummary && crateSummary.classList.contains('visible');
    resetCrateOverlay();
    if (!summaryVisible && rewardLabel) {
        addActivityEntry(`🎉 ${rewardLabel}`, true);
    }
}

function buildCrateCards(pool, selection) {
    const sanitizedPool = Array.isArray(pool) && pool.length > 0
        ? pool.map((entry) => ({
            id: entry.id,
            label: entry.label || 'Nagroda',
            icon: entry.icon || '🎁',
            rarity: (entry.rarity || 'pospolity').toLowerCase()
        }))
        : [];

    const basePool = sanitizedPool.length > 0 ? sanitizedPool : [
        {
            id: selection.id,
            label: selection.label || 'Nagroda',
            icon: selection.icon || '🎁',
            rarity: (selection.rarity || 'pospolity').toLowerCase()
        }
    ];

    const randomFromPool = () => {
        const entry = basePool[Math.floor(Math.random() * basePool.length)];
        return { ...entry };
    };

    const cards = [];
    for (let i = 0; i < 6; i += 1) {
        cards.push(randomFromPool());
    }

    cards.push({
        id: selection.id,
        label: selection.label || 'Nagroda',
        icon: selection.icon || '🎁',
        rarity: (selection.rarity || 'pospolity').toLowerCase(),
        winning: true
    });

    for (let i = 0; i < 6; i += 1) {
        cards.push(randomFromPool());
    }

    return cards;
}

function playCrateAnimation(item, context) {
    if (!crateOverlay || !context || context.type !== 'crate') {
        return;
    }

    crateOverlay.classList.remove('hidden');
    crateTitle.textContent = context.crateLabel || item.label || 'Skrzynia';
    crateSummary.classList.remove('visible');

    const highlight = context.highlight || '#62f6ff';
    crateSummary.style.borderColor = highlight;
    crateSummary.style.boxShadow = `0 0 32px ${highlight}55`;
    crateRewardRarity.style.color = highlight;

    const selection = context.selection || {};
    crateRewardIcon.textContent = selection.icon || item.icon || '🎁';
    crateRewardLabel.textContent = selection.label || 'Nagroda';
    crateRewardRarity.textContent = selection.rarity || 'tajemnicza';

    crateTrack.innerHTML = '';
    const cards = buildCrateCards(context.poolPreview, selection);

    cards.forEach((card) => {
        const element = document.createElement('div');
        element.className = 'crate-card';
        element.dataset.rarity = card.rarity;

        const icon = document.createElement('span');
        icon.className = 'icon';
        icon.textContent = card.icon || '🎁';

        const label = document.createElement('span');
        label.className = 'label';
        label.textContent = card.label;

        element.appendChild(icon);
        element.appendChild(label);
        if (card.winning) {
            element.dataset.winning = 'true';
        }

        crateTrack.appendChild(element);
    });

    requestAnimationFrame(() => {
        const winningElement = crateTrack.querySelector('[data-winning="true"]');
        const cardElement = crateTrack.querySelector('.crate-card');
        if (!winningElement || !cardElement) {
            crateSummary.classList.add('visible');
            addActivityEntry(`🎉 ${selection.label || item.label}`, true);
            return;
        }

        const cardRect = cardElement.getBoundingClientRect();
        const trackStyles = window.getComputedStyle(crateTrack);
        const gapValue = parseFloat(trackStyles.columnGap || trackStyles.gap || '0') || 0;
        const cardWidth = cardRect.width;
        const cardsBefore = Array.from(crateTrack.children).indexOf(winningElement);
        const reelWidth = crateReel.getBoundingClientRect().width;
        const targetOffset = Math.max(0, cardsBefore * (cardWidth + gapValue) - (reelWidth / 2 - cardWidth / 2));

        if (state.crateAnimation) {
            state.crateAnimation.cancel();
        }

        state.crateAnimation = crateTrack.animate([
            { transform: 'translateX(0)' },
            { transform: `translateX(-${targetOffset}px)` }
        ], {
            duration: 4600,
            easing: 'cubic-bezier(0.12, 0.01, 0, 1)',
            fill: 'forwards'
        });

        state.crateAnimation.onfinish = () => {
            winningElement.classList.add('winning');
            crateSummary.classList.add('visible');
            addActivityEntry(`🎉 ${selection.label || item.label}`, true);
            state.crateAnimation = null;
        };
    });
}

function scrollToSection(target) {
    if (!target) {
        return;
    }
    const section = document.querySelector(`[data-section="${target}"]`);
    if (section && section.scrollIntoView) {
        section.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

if (heroPrimary) {
    heroPrimary.addEventListener('click', () => {
        scrollToSection(heroPrimary.dataset.target);
    });
}

if (heroSecondary) {
    heroSecondary.addEventListener('click', () => {
        scrollToSection(heroSecondary.dataset.target);
    });
}

if (confirmPurchase) {
    confirmPurchase.addEventListener('click', () => {
        if (!state.selectedItem) {
            return;
        }

        if (modalFeedback) {
            modalFeedback.style.color = '#3bc9ff';
            modalFeedback.textContent = 'Przetwarzanie...';
        }

        fetch(`https://${GetParentResourceName()}/purchaseItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify({ id: state.selectedItem.id })
        });
    });
}

if (cancelPurchase) {
    cancelPurchase.addEventListener('click', () => {
        closeModal();
    });
}

if (crateContinue) {
    crateContinue.addEventListener('click', () => {
        closeCrateOverlay();
    });
}

if (crateClose) {
    crateClose.addEventListener('click', () => {
        closeCrateOverlay();
    });
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) {
        return;
    }

    const action = data.action;

    if (action === 'open') {
        state.items = Array.isArray(data.items) ? data.items : [];
        state.itemLookup = {};
        state.items.forEach((item) => {
            state.itemLookup[item.id] = item;
        });
        state.currency = data.currency || state.currency;
        state.layout = data.layout || state.layout;

        document.body.classList.add('market-active');
        if (app) {
            app.classList.remove('hidden');
        }

        applyHeroLayout();
        renderSections();
        if (typeof data.balance === 'number') {
            setWallet(data.balance);
        } else {
            setWallet(state.wallet);
        }
        resetActivityPlaceholder();
        return;
    }

    if (action === 'close') {
        if (app) {
            app.classList.add('hidden');
        }
        document.body.classList.remove('market-active');
        closeModal();
        resetCrateOverlay();
        return;
    }

    if (action === 'updateWallet') {
        state.currency = data.currency || state.currency;
        if (typeof data.balance === 'number') {
            setWallet(data.balance);
        }
        return;
    }

    if (action === 'purchaseResult') {
        const result = data.result || {};
        if (typeof result.balance === 'number') {
            setWallet(result.balance);
        }

        if (!state.selectedItem) {
            return;
        }

        if (result.success) {
            if (result.rewardContext && result.rewardContext.type === 'crate') {
                const purchasedItem = state.selectedItem;
                closeModal();
                state.selectedItem = null;
                playCrateAnimation(purchasedItem, result.rewardContext);
            } else {
                if (modalFeedback) {
                    modalFeedback.style.color = '#4be7b0';
                    modalFeedback.textContent = `Zakupiono ${state.selectedItem.label}!`;
                }
                addActivityEntry(`✅ ${state.selectedItem.label}`, true);
                setTimeout(() => {
                    closeModal();
                    state.selectedItem = null;
                }, 1100);
            }
        } else {
            if (modalFeedback) {
                modalFeedback.style.color = '#ff6f91';
                const messages = {
                    insufficient_funds: 'Niewystarczająca liczba monet.',
                    cooldown: 'Odczekaj chwilę przed kolejnym zakupem.',
                    transaction_error: 'Błąd transakcji. Spróbuj ponownie.',
                    reward_failed: 'Nie udało się dostarczyć nagrody.',
                    item_not_found: 'Przedmiot niedostępny.',
                    framework_unavailable: 'Framework niedostępny.'
                };
                modalFeedback.textContent = messages[result.reason] || 'Zakup nieudany.';
            }
            addActivityEntry(`⛔ ${state.selectedItem.label}`, false);
        }
        return;
    }

    if (action === 'crateReveal') {
        const result = data.result || {};
        if (result.rewardContext && result.rewardContext.type === 'crate' && state.selectedItem) {
            playCrateAnimation(state.selectedItem, result.rewardContext);
        }
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (crateOverlay && !crateOverlay.classList.contains('hidden')) {
            closeCrateOverlay();
            return;
        }
        fetch(`https://${GetParentResourceName()}/closeMarket`, {
            method: 'POST',
            body: JSON.stringify({})
        });
    }
});

window.addEventListener('load', () => {
    fetch(`https://${GetParentResourceName()}/ready`, {
        method: 'POST',
        body: JSON.stringify({})
    });
});
