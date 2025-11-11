const state = {
    items: [],
    itemLookup: {},
    currency: { symbol: '💎', name: 'Ghost Coin' },
    layout: { sections: [] },
    selectedItem: null,
    wallet: 0,
    activity: [],
    crateAnimation: null,
    heroCountdownConfig: null,
    heroCountdownRuntime: null,
    heroCountdownResolved: null,
    heroCountdownTimer: null,
    statusClockTimer: null
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
const heroSection = document.getElementById('heroSection');
const contentScroll = document.getElementById('contentScroll');
const walletDisplay = document.getElementById('walletDisplay');
const statusClock = document.getElementById('statusClock');
const navLinks = Array.from(document.querySelectorAll('.nav-link'));
const crateOverlay = document.getElementById('crateOverlay');
const crateTitle = document.getElementById('crateTitle');
const crateTrack = document.getElementById('crateTrack');
const crateReel = document.getElementById('crateReel');
const crateSummary = document.getElementById('crateSummary');
const crateRewardProp = document.getElementById('crateRewardProp');
const cratePropIcon = document.getElementById('cratePropIcon');
const crateRewardLabel = document.getElementById('crateRewardLabel');
const crateRewardDetail = document.getElementById('crateRewardDetail');
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

function withAlpha(hex, alpha) {
    if (typeof hex !== 'string' || !hex.startsWith('#')) {
        return '';
    }

    let normalized = hex;
    if (hex.length === 4) {
        const r = hex[1];
        const g = hex[2];
        const b = hex[3];
        normalized = `#${r}${r}${g}${g}${b}${b}`;
    }

    if (normalized.length !== 7) {
        return '';
    }

    return `${normalized}${alpha}`;
}

function normalizeRarity(value) {
    return typeof value === 'string' ? value.toLowerCase() : '';
}

function formatRarityLabel(value) {
    const normalized = normalizeRarity(value);
    if (!normalized) {
        return '';
    }

    return normalized.charAt(0).toUpperCase() + normalized.slice(1);
}

function normalizeVisualType(type) {
    if (typeof type !== 'string') {
        return '';
    }

    const normalized = type.trim().toLowerCase();
    const allowed = ['vehicle', 'weapon', 'crate', 'boost', 'service'];
    return allowed.includes(normalized) ? normalized : '';
}

function buildCardPreview(item) {
    if (!item) {
        return { preview: null, accent: null };
    }

    const visual = item.visual || {};
    const preview = document.createElement('div');
    preview.className = 'card-preview';

    const visualType = normalizeVisualType(visual.type);
    if (visualType) {
        preview.classList.add(`card-preview--${visualType}`);
    }

    const accent = visual.accent || (item.rewardData && item.rewardData.highlight) || null;
    const accentIsHex = typeof accent === 'string' && accent.startsWith('#') && (accent.length === 7 || accent.length === 4);
    if (accent) {
        preview.style.setProperty('--preview-accent', accent);
    }

    if (accentIsHex) {
        const primary = withAlpha(accent, '33') || `${accent}33`;
        const border = withAlpha(accent, '44') || `${accent}44`;
        const outline = withAlpha(accent, '22') || `${accent}22`;
        preview.style.background = `linear-gradient(160deg, ${primary}, rgba(8, 16, 38, 0.88))`;
        preview.style.borderBottom = `1px solid ${border}`;
        preview.style.boxShadow = `inset 0 0 0 1px ${outline}`;
    } else {
        preview.style.background = 'linear-gradient(160deg, rgba(18, 36, 78, 0.75), rgba(8, 16, 38, 0.9))';
    }

    if (visual.image) {
        preview.style.backgroundImage = `linear-gradient(160deg, rgba(8, 16, 38, 0.2), rgba(8, 16, 38, 0.85)), url(${visual.image})`;
        preview.style.backgroundSize = 'cover';
        preview.style.backgroundPosition = 'center';
    }

    const icon = visual.icon || item.icon || '💎';
    const heading = visual.name || visual.label || item.label || '';
    const model = visual.model || visual.code || '';
    const tagline = visual.tagline || '';

    if (visualType === 'vehicle' || visualType === 'weapon') {
        const label = document.createElement('span');
        label.className = 'preview-label';
        label.textContent = heading;
        preview.appendChild(label);

        if (model) {
            const meta = document.createElement('span');
            meta.className = 'preview-meta';
            meta.textContent = model.toUpperCase();
            preview.appendChild(meta);
        }

        if (tagline) {
            const tag = document.createElement('span');
            tag.className = 'preview-tagline';
            tag.textContent = tagline;
            preview.appendChild(tag);
        }
    } else {
        const iconElement = document.createElement('span');
        iconElement.className = 'preview-icon';
        iconElement.textContent = icon;
        preview.appendChild(iconElement);

        if (heading) {
            const label = document.createElement('span');
            label.className = 'preview-label';
            label.textContent = heading;
            preview.appendChild(label);
        }

        if (tagline) {
            const tag = document.createElement('span');
            tag.className = 'preview-tagline';
            tag.textContent = tagline;
            preview.appendChild(tag);
        }
    }

    return { preview, accent };
}

function applyCardAccent(card, accent) {
    if (!card || !accent) {
        return;
    }

    card.classList.add('item-card--accented');
    card.style.setProperty('--item-accent', accent);

    if (typeof accent === 'string' && accent.startsWith('#') && accent.length === 7) {
        card.style.setProperty('--item-accent-soft', `${accent}55`);
    }
}

function applyPropVisual(container, iconElement, prop, fallbackIcon, fallbackAccent) {
    const accent = (prop && typeof prop.color === 'string' && prop.color) || fallbackAccent || '#62f6ff';

    if (iconElement) {
        iconElement.textContent = (prop && prop.icon) || fallbackIcon || '🎁';
    }

    if (!container) {
        return accent;
    }

    if (prop && prop.image) {
        container.style.backgroundImage = `url(${prop.image})`;
        container.style.backgroundSize = 'cover';
        container.style.backgroundPosition = 'center';
    } else {
        container.style.backgroundImage = '';
    }

    const background = prop && prop.background
        ? prop.background
        : `linear-gradient(150deg, ${withAlpha(accent, '33') || `${accent}33`}, rgba(12, 26, 60, 0.85))`;

    container.style.background = background;
    container.style.boxShadow = `0 26px 70px ${withAlpha(accent, '33') || `${accent}33`}`;
    container.style.borderColor = withAlpha(accent, '55') || accent;

    return accent;
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

    if (item.category) {
        card.dataset.category = item.category;
    }

    const visualType = normalizeVisualType(item.visual && item.visual.type);
    if (visualType) {
        card.classList.add(`item-card--${visualType}`);
    }

    const accent = (item.visual && item.visual.accent) || (item.rewardData && item.rewardData.highlight);
    if (accent) {
        applyCardAccent(card, accent);
    }

    const includePreview = cardVariant !== 'list';
    if (includePreview) {
        const { preview, accent: previewAccent } = buildCardPreview(item);
        if (preview) {
            card.classList.add('item-card--with-preview');
            card.appendChild(preview);
        }

        if (!accent && previewAccent) {
            applyCardAccent(card, previewAccent);
        }
    }

    const body = document.createElement('div');
    body.className = 'card-body';

    const header = document.createElement('div');
    header.className = 'card-header';

    const icon = document.createElement('span');
    icon.className = 'card-icon';
    icon.textContent = (item.icon || (item.visual && item.visual.icon) || '💎');
    header.appendChild(icon);

    const meta = document.createElement('div');
    meta.className = 'card-meta';

    const title = document.createElement('h3');
    title.className = 'card-title';
    title.textContent = item.label;
    meta.appendChild(title);

    const typeValue = formatTypeLabel(item.rewardData && item.rewardData.type);
    if (typeValue) {
        const type = document.createElement('span');
        type.className = 'card-type';
        type.textContent = typeValue;
        meta.appendChild(type);
    }

    header.appendChild(meta);
    body.appendChild(header);

    const description = document.createElement('p');
    description.className = 'card-description';
    description.textContent = item.description || '';
    body.appendChild(description);

    const footer = document.createElement('div');
    footer.className = 'card-footer';

    const price = document.createElement('span');
    price.className = 'card-price';
    price.textContent = formatPrice(item.price);
    footer.appendChild(price);

    const button = document.createElement('button');
    button.className = 'btn ghost card-action';
    button.textContent = 'Kup';
    footer.appendChild(button);

    body.appendChild(footer);
    card.appendChild(body);

    card.addEventListener('click', () => openModal(item));

    button.addEventListener('click', (event) => {
        event.stopPropagation();
        openModal(item);
    });

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

function clearHeroCountdownTimer() {
    if (state.heroCountdownTimer) {
        clearInterval(state.heroCountdownTimer);
        state.heroCountdownTimer = null;
    }
}

function computeCountdownSnapshot(endAt) {
    if (typeof endAt !== 'number') {
        return null;
    }

    const diff = endAt - Date.now();
    if (!Number.isFinite(diff)) {
        return null;
    }

    if (diff <= 0) {
        return { completed: true };
    }

    const totalSeconds = Math.floor(diff / 1000);
    const days = Math.floor(totalSeconds / 86400);
    const hours = Math.floor((totalSeconds % 86400) / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    let text;
    if (days > 0) {
        text = `${String(days).padStart(2, '0')}d ${String(hours).padStart(2, '0')}h ${String(minutes).padStart(2, '0')}m`;
    } else {
        text = `${String(hours).padStart(2, '0')}h ${String(minutes).padStart(2, '0')}m ${String(seconds).padStart(2, '0')}s`;
    }

    return { completed: false, text };
}

function updateHeroCountdownLabel(label, fallback, endAt) {
    if (!heroCountdown) {
        return false;
    }

    const finalLabel = (typeof label === 'string' && label.trim() !== '') ? label.trim() : '';
    const fallbackText = (typeof fallback === 'string' && fallback.trim() !== '') ? fallback.trim() : '';

    if (!endAt) {
        if (fallbackText) {
            heroCountdown.textContent = finalLabel ? `${finalLabel} ${fallbackText}` : fallbackText;
        } else {
            heroCountdown.textContent = finalLabel;
        }
        return false;
    }

    const snapshot = computeCountdownSnapshot(endAt);
    if (!snapshot) {
        if (fallbackText) {
            heroCountdown.textContent = finalLabel ? `${finalLabel} ${fallbackText}` : fallbackText;
        } else {
            heroCountdown.textContent = finalLabel;
        }
        return false;
    }

    if (snapshot.completed) {
        heroCountdown.textContent = finalLabel ? `${finalLabel} Zakończono` : 'Zakończono';
        return true;
    }

    heroCountdown.textContent = finalLabel ? `${finalLabel} ${snapshot.text}` : snapshot.text;
    return false;
}

function refreshHeroCountdown() {
    const config = state.heroCountdownConfig;
    const runtime = state.heroCountdownRuntime;

    let label = '';
    let fallback = '';

    if (typeof config === 'string') {
        label = config;
    } else if (config && typeof config === 'object') {
        if (typeof config.label === 'string') {
            label = config.label;
        }
        if (typeof config.fallback === 'string') {
            fallback = config.fallback;
        }
    }

    if (runtime && typeof runtime === 'object') {
        if (typeof runtime.label === 'string' && runtime.label.trim() !== '') {
            label = runtime.label;
        }
        if (typeof runtime.fallback === 'string' && runtime.fallback.trim() !== '') {
            fallback = runtime.fallback;
        }
    }

    const endAt = runtime && typeof runtime.endAt === 'number' ? runtime.endAt : null;

    state.heroCountdownResolved = { label, fallback, endAt };

    updateHeroCountdownLabel(label, fallback, endAt);
}

function tickHeroCountdown() {
    if (!state.heroCountdownResolved) {
        return;
    }

    const { label, fallback, endAt } = state.heroCountdownResolved;
    updateHeroCountdownLabel(label, fallback, endAt);
}

function normalizeRuntimeCountdown(runtime) {
    if (!runtime || typeof runtime !== 'object') {
        return {};
    }

    const normalized = {};

    if (typeof runtime.label === 'string' && runtime.label.trim() !== '') {
        normalized.label = runtime.label;
    }

    if (typeof runtime.fallback === 'string' && runtime.fallback.trim() !== '') {
        normalized.fallback = runtime.fallback;
    }

    let endAt = Number(runtime.endAt);
    if (!Number.isNaN(endAt) && endAt > 0) {
        if (endAt < 1e12) {
            endAt *= 1000;
        }

        let serverTime = Number(runtime.serverTime);
        if (!Number.isNaN(serverTime) && serverTime > 0) {
            if (serverTime < 1e12) {
                serverTime *= 1000;
            }

            const offset = endAt - serverTime;
            endAt = Date.now() + offset;
        }

        normalized.endAt = endAt;
    }

    return normalized;
}

function applyEventState(update) {
    if (!update || typeof update !== 'object') {
        return;
    }

    if (update.heroCountdown) {
        state.heroCountdownRuntime = normalizeRuntimeCountdown(update.heroCountdown);
        refreshHeroCountdown();
    }
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

    state.heroCountdownConfig = hero.countdown || null;
    refreshHeroCountdown();

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
    if (crateSummary) {
        crateSummary.classList.remove('visible');
        crateSummary.style.boxShadow = '';
        crateSummary.style.borderColor = '';
    }
    if (crateRewardRarity) {
        crateRewardRarity.style.color = '';
    }
    if (crateRewardDetail) {
        crateRewardDetail.textContent = '';
    }
    if (crateRewardProp) {
        crateRewardProp.style.background = '';
        crateRewardProp.style.borderColor = '';
        crateRewardProp.style.boxShadow = '';
        crateRewardProp.style.backgroundImage = '';
    }
    if (cratePropIcon) {
        cratePropIcon.textContent = '🎁';
    }
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

function buildCrateCards(pool, selection, highlight) {
    const sanitizedPool = Array.isArray(pool) && pool.length > 0
        ? pool.map((entry) => ({
            id: entry.id,
            label: entry.label || 'Nagroda',
            icon: entry.icon || '🎁',
            rarity: normalizeRarity(entry.rarity || 'pospolity'),
            prop: entry.prop
        }))
        : [];

    const basePool = sanitizedPool.length > 0 ? sanitizedPool : [
        {
            id: selection.id,
            label: selection.label || 'Nagroda',
            icon: selection.icon || '🎁',
            rarity: normalizeRarity(selection.rarity || 'pospolity'),
            prop: selection.prop
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
        rarity: normalizeRarity(selection.rarity || 'pospolity'),
        prop: selection.prop,
        winning: true,
        highlight
    });

    for (let i = 0; i < 6; i += 1) {
        cards.push(randomFromPool());
    }

    return cards;
}

function formatCrateDetail(selection) {
    if (!selection) {
        return '';
    }

    if (selection.displayName) {
        return selection.displayName;
    }

    const details = selection.rewardDetails || {};
    if (details.displayName) {
        return details.displayName;
    }

    const rewardType = details.rewardType || selection.rewardType;

    if (rewardType === 'vehicle' && details.model) {
        return String(details.model).toUpperCase();
    }

    if (rewardType === 'weapon' && details.weapon) {
        return String(details.weapon).toUpperCase();
    }

    if (rewardType === 'money' && typeof details.amount === 'number') {
        const formatted = details.amount.toLocaleString('pl-PL');
        return details.account ? `${formatted} ${details.account}` : formatted;
    }

    if (rewardType === 'item' && details.item) {
        const count = typeof details.count === 'number' && details.count > 1 ? `${details.count}× ` : '';
        return `${count}${details.item}`;
    }

    if (rewardType === 'group' && details.group) {
        return details.group;
    }

    return formatTypeLabel(rewardType);
}

function playCrateAnimation(item, context) {
    if (!crateOverlay || !context || context.type !== 'crate') {
        return;
    }

    crateOverlay.classList.remove('hidden');
    crateTitle.textContent = context.crateLabel || item.label || 'Skrzynia';
    if (crateSummary) {
        crateSummary.classList.remove('visible');
    }

    const highlight = context.highlight || '#62f6ff';
    const selection = context.selection || {};
    const summaryAccent = applyPropVisual(
        crateRewardProp,
        cratePropIcon,
        selection.prop,
        selection.icon || item.icon,
        highlight
    );

    const activeAccent = summaryAccent || highlight;
    const borderColor = withAlpha(activeAccent, '55') || activeAccent;
    const glowColor = withAlpha(activeAccent, '33') || activeAccent;

    crateRewardLabel.textContent = selection.label || 'Nagroda';
    if (crateRewardDetail) {
        crateRewardDetail.textContent = formatCrateDetail(selection);
    }
    if (crateRewardRarity) {
        crateRewardRarity.textContent = formatRarityLabel(selection.rarity) || 'Tajemnicza';
        crateRewardRarity.style.color = activeAccent;
    }

    if (crateSummary) {
        crateSummary.style.borderColor = borderColor;
        crateSummary.style.boxShadow = `0 26px 70px ${glowColor}`;
    }

    crateTrack.innerHTML = '';
    const cards = buildCrateCards(context.poolPreview, selection, activeAccent);

    cards.forEach((card) => {
        const element = document.createElement('div');
        element.className = 'crate-card';

        const rarityValue = normalizeRarity(card.rarity);
        if (rarityValue) {
            element.dataset.rarity = rarityValue;
        }

        const propContainer = document.createElement('div');
        propContainer.className = 'prop';
        const propIcon = document.createElement('span');
        propIcon.className = 'prop-icon';
        propContainer.appendChild(propIcon);

        const info = document.createElement('div');
        info.className = 'info';

        const label = document.createElement('span');
        label.className = 'label';
        label.textContent = card.label || 'Nagroda';

        const rarityLabel = document.createElement('span');
        rarityLabel.className = 'rarity';
        rarityLabel.textContent = formatRarityLabel(card.rarity) || '';

        info.appendChild(label);
        info.appendChild(rarityLabel);

        const accent = applyPropVisual(propContainer, propIcon, card.prop, card.icon, activeAccent);
        if (accent) {
            const cardBorder = withAlpha(accent, '44') || accent;
            const cardGlow = withAlpha(accent, '2a') || accent;
            if (cardBorder) {
                element.style.borderColor = cardBorder;
            }
            if (cardGlow) {
                element.style.boxShadow = `0 24px 70px ${cardGlow}`;
            }
        }

        element.appendChild(propContainer);
        element.appendChild(info);

        if (card.winning) {
            element.dataset.winning = 'true';
        }

        crateTrack.appendChild(element);
    });

    requestAnimationFrame(() => {
        const winningElement = crateTrack.querySelector('[data-winning="true"]');
        const cardElement = crateTrack.querySelector('.crate-card');
        if (!winningElement || !cardElement) {
            if (crateSummary) {
                crateSummary.classList.add('visible');
            }
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
            if (crateSummary) {
                crateSummary.classList.add('visible');
            }
            addActivityEntry(`🎉 ${selection.label || item.label}`, true);
            state.crateAnimation = null;
        };
    });
}

let navResetTimer = null;

function clearNavResetTimer() {
    if (navResetTimer) {
        clearTimeout(navResetTimer);
        navResetTimer = null;
    }
}

function updateStatusClock() {
    if (!statusClock) {
        return;
    }

    const now = new Date();
    statusClock.textContent = now.toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' });
}

function startStatusClock() {
    if (!statusClock) {
        return;
    }

    updateStatusClock();
    if (state.statusClockTimer) {
        clearInterval(state.statusClockTimer);
    }
    state.statusClockTimer = setInterval(updateStatusClock, 1000);
}

function stopStatusClock() {
    if (state.statusClockTimer) {
        clearInterval(state.statusClockTimer);
        state.statusClockTimer = null;
    }
}

function focusWallet() {
    if (!walletDisplay) {
        return;
    }

    walletDisplay.classList.add('pulse');
    setTimeout(() => {
        walletDisplay.classList.remove('pulse');
    }, 1600);
}

function setActiveNav(target) {
    navLinks.forEach((link) => {
        const linkTarget = link.dataset.target || '';
        if (linkTarget === target) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

function updateNavForPosition() {
    if (!contentScroll) {
        return;
    }

    const scrollTop = contentScroll.scrollTop || 0;
    const activity = document.querySelector('[data-section="activity"]');

    if (activity) {
        const threshold = Math.max(activity.offsetTop - 120, 0);
        if (scrollTop >= threshold) {
            setActiveNav('activity');
            return;
        }
    }

    if (scrollTop > 40) {
        setActiveNav('sections');
    } else {
        setActiveNav('hero');
    }
}

function scrollToSection(target) {
    if (!target) {
        return null;
    }

    if (target === 'hero') {
        if (heroSection && heroSection.scrollIntoView) {
            heroSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        return heroSection;
    }

    if (target === 'wallet') {
        if (heroSection && heroSection.scrollIntoView) {
            heroSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
        focusWallet();
        return walletDisplay;
    }

    if (!contentScroll) {
        const fallbackSection = document.querySelector(`[data-section="${target}"]`);
        if (fallbackSection && fallbackSection.scrollIntoView) {
            fallbackSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
        return fallbackSection;
    }

    if (target === 'sections') {
        contentScroll.scrollTo({ top: 0, behavior: 'smooth' });
        return sectionsRoot;
    }

    const section = target === 'activity'
        ? document.querySelector('[data-section="activity"]')
        : document.querySelector(`[data-section="${target}"]`);

    if (section && contentScroll.contains(section)) {
        const offset = section.offsetTop;
        contentScroll.scrollTo({ top: offset, behavior: 'smooth' });
        return section;
    }

    if (section && section.scrollIntoView) {
        section.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    return section;
}

if (contentScroll) {
    contentScroll.addEventListener('scroll', () => {
        if (navResetTimer) {
            return;
        }
        updateNavForPosition();
    });
}

if (navLinks.length > 0) {
    navLinks.forEach((link) => {
        link.addEventListener('click', () => {
            const target = link.dataset.target || '';
            setActiveNav(target || 'hero');
            scrollToSection(target);

            clearNavResetTimer();

            if (target === 'wallet') {
                navResetTimer = setTimeout(() => {
                    clearNavResetTimer();
                    updateNavForPosition();
                }, 2200);
            } else if (target !== 'hero') {
                navResetTimer = setTimeout(() => {
                    clearNavResetTimer();
                    updateNavForPosition();
                }, 900);
            }
        });
    });
}

if (heroPrimary) {
    heroPrimary.addEventListener('click', () => {
        const target = heroPrimary.dataset.target || '';
        if (target) {
            setActiveNav(target);
        }
        scrollToSection(target);
    });
}

if (heroSecondary) {
    heroSecondary.addEventListener('click', () => {
        const target = heroSecondary.dataset.target || '';
        if (target) {
            setActiveNav(target);
        }
        scrollToSection(target);
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

        startStatusClock();
        clearNavResetTimer();
        setActiveNav('hero');
        applyHeroLayout();
        renderSections();
        updateNavForPosition();
        if (data.eventState) {
            applyEventState(data.eventState);
        }
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
        stopStatusClock();
        clearNavResetTimer();
        setActiveNav('hero');
        closeModal();
        resetCrateOverlay();
        clearHeroCountdownTimer();
        return;
    }

    if (action === 'updateEventState') {
        applyEventState(data.state || data);
        return;
    }

    if (action === 'tickCountdown') {
        tickHeroCountdown();
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
