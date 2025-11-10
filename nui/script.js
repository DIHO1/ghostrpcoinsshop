const state = {
    items: [],
    currency: { symbol: '💎', name: 'Ghost Coin' },
    selectedItem: null,
    wallet: 0,
    activeView: 'overview',
    activity: [],
    crateAnimation: null
    activity: []
};

const app = document.getElementById('app');
const itemsContainer = document.getElementById('itemsContainer');
const walletValue = document.getElementById('walletValue');
const modal = document.getElementById('modal');
const modalTitle = document.getElementById('modalTitle');
const modalDescription = document.getElementById('modalDescription');
const modalFeedback = document.getElementById('modalFeedback');
const confirmPurchase = document.getElementById('confirmPurchase');
const cancelPurchase = document.getElementById('cancelPurchase');
const nav = document.getElementById('viewNav');
const navGlow = document.getElementById('navGlow');
const navButtons = nav ? nav.querySelectorAll('.nav-item') : [];
const viewPanels = document.querySelectorAll('.view-panel');
const activityLog = document.getElementById('activityLog');
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
    return `${state.currency.symbol} ${amount}`;
}

function setWallet(amount) {
    state.wallet = amount;
    walletValue.textContent = `${formatPrice(amount)}`;
    if (state.currency.color) {
        walletValue.style.color = state.currency.color;
    }
}

function renderItems() {
    itemsContainer.innerHTML = '';

    if (!state.items.length) {
        const empty = document.createElement('p');
        empty.className = 'placeholder';
        empty.textContent = 'Aktualnie brak towaru do zakupu.';
        itemsContainer.appendChild(empty);
        return;
    }

    state.items.forEach((item) => {
        const card = document.createElement('article');
        card.className = 'item-card';
        card.dataset.id = item.id;

        card.innerHTML = `
            <span class="item-icon">${item.icon || '💎'}</span>
            <h3 class="item-label">${item.label}</h3>
            <p class="item-description">${item.description}</p>
            <div class="item-footer">
                <span class="item-price">${formatPrice(item.price)}</span>
                <span class="item-type">${item.rewardData.type.toUpperCase()}</span>
            </div>
        `;

        card.addEventListener('click', () => openModal(item));
        itemsContainer.appendChild(card);
    });
}

function moveNavGlow(target) {
    if (!navGlow || !target) {
        return;
    }

    const index = Number(target.dataset.index || 0);
    navGlow.style.transform = `translateX(${index * 100}%)`;
}

function setActiveView(view) {
    state.activeView = view;

    viewPanels.forEach((panel) => {
        panel.classList.toggle('active', panel.dataset.view === view);
    });

    navButtons.forEach((button) => {
        const isActive = button.dataset.view === view;
        button.classList.toggle('active', isActive);
        if (isActive) {
            moveNavGlow(button);
        }
    });

    if (view === 'shop') {
        renderItems();
    }
}

function addActivityEntry(label, success) {
    if (!activityLog) {
        return;
    }

    if (activityLog.querySelector('.placeholder')) {
        activityLog.innerHTML = '';
    }

    const entry = document.createElement('div');
    entry.className = 'activity-entry';

    const message = document.createElement('span');
    message.className = 'label';
    message.textContent = label;

    const time = document.createElement('span');
    time.className = 'time';
    time.textContent = new Date().toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' });

    if (!success) {
        message.style.color = '#ff416c';
    }

    entry.appendChild(message);
    entry.appendChild(time);
    activityLog.prepend(entry);

    state.activity.unshift({ label, success, createdAt: Date.now() });
    if (state.activity.length > 8) {
        state.activity.pop();
        const lastEntry = activityLog.querySelector('.activity-entry:last-of-type');
        if (lastEntry) {
            lastEntry.remove();
        }
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
    const summaryWasVisible = crateSummary && crateSummary.classList.contains('visible');
    resetCrateOverlay();
    setActiveView('shop');
    if (!summaryWasVisible && rewardLabel) {
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
    crateRewardRarity.textContent = (selection.rarity || 'tajemnicza');

    crateTrack.innerHTML = '';

    const cards = buildCrateCards(context.poolPreview, selection);

    cards.forEach((card) => {
        const cardElement = document.createElement('div');
        cardElement.className = 'crate-card';
        cardElement.dataset.rarity = card.rarity;

        const icon = document.createElement('span');
        icon.className = 'icon';
        icon.textContent = card.icon || '🎁';

        const label = document.createElement('span');
        label.className = 'label';
        label.textContent = card.label;

        cardElement.appendChild(icon);
        cardElement.appendChild(label);
        if (card.winning) {
            cardElement.dataset.winning = 'true';
        }

        crateTrack.appendChild(cardElement);
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
        const totalWidth = cardsBefore * (cardWidth + gapValue);
        const reelWidth = crateReel.getBoundingClientRect().width;
        const targetOffset = Math.max(0, totalWidth - (reelWidth / 2 - cardWidth / 2));

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

navButtons.forEach((button) => {
    button.addEventListener('click', () => {
        const view = button.dataset.view;
        setActiveView(view);
    });
});

if (navButtons.length > 0) {
    if (navGlow) {
        navGlow.style.width = `${100 / navButtons.length}%`;
    }

    const activeButton = document.querySelector('.nav-item.active') || navButtons[0];
    moveNavGlow(activeButton);
}

function openModal(item) {
    state.selectedItem = item;
    modalTitle.textContent = 'Potwierdzenie zakupu';
    modalDescription.textContent = `Czy na pewno kupić ${item.label} za ${formatPrice(item.price)}?`;
    modalFeedback.textContent = '';
    modal.classList.remove('hidden');
}

function closeModal() {
    state.selectedItem = null;
    modal.classList.add('hidden');
    modalFeedback.textContent = '';
}

confirmPurchase.addEventListener('click', () => {
    if (!state.selectedItem) {
        return;
    }

    modalFeedback.style.color = '#29f1ff';
    modalFeedback.textContent = 'Przetwarzanie...';

    fetch(`https://${GetParentResourceName()}/purchaseItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify({ id: state.selectedItem.id })
    });
});

cancelPurchase.addEventListener('click', () => {
    closeModal();
});

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

    switch (data.action) {
        case 'open':
            state.items = data.items || [];
            state.currency = data.currency || state.currency;
            document.body.classList.add('market-active');
            app.classList.remove('hidden');
            setActiveView('shop');
            setWallet(state.wallet);
            break;
        case 'close':
            app.classList.add('hidden');
            closeModal();
            resetCrateOverlay();
            document.body.classList.remove('market-active');
            setActiveView('overview');
            break;
        case 'updateWallet':
            state.currency = data.currency || state.currency;
            if (typeof data.balance === 'number') {
                setWallet(data.balance);
            }
            break;
        case 'purchaseResult':
            const result = data.result || {};
            if (typeof result.balance === 'number') {
                setWallet(result.balance);
            }

            if (!state.selectedItem) {
                break;
            }

            if (result.success) {
                if (result.rewardContext && result.rewardContext.type === 'crate') {
                    const purchasedItem = state.selectedItem;
                    closeModal();
                    state.selectedItem = null;
                    playCrateAnimation(purchasedItem, result.rewardContext);
                } else {
                    modalFeedback.style.color = '#7dffb3';
                    modalFeedback.textContent = `Zakupiono ${state.selectedItem.label}!`;
                    addActivityEntry(`✅ ${state.selectedItem.label}`, true);
                    setTimeout(() => {
                        modalFeedback.textContent = '';
                        closeModal();
                        state.selectedItem = null;
                    }, 1200);
                }
                modalFeedback.style.color = '#7dffb3';
                modalFeedback.textContent = `Zakupiono ${state.selectedItem.label}!`;
                addActivityEntry(`✅ ${state.selectedItem.label}`, true);
                setTimeout(() => {
                    modalFeedback.textContent = '';
                    closeModal();
                }, 1200);
            } else {
                modalFeedback.style.color = '#ff416c';
                const messages = {
                    insufficient_funds: 'Niewystarczająca liczba monet.',
                    cooldown: 'Odczekaj chwilę przed kolejnym zakupem.',
                    transaction_error: 'Błąd transakcji. Spróbuj ponownie.',
                    reward_failed: 'Nie udało się dostarczyć nagrody.',
                    item_not_found: 'Przedmiot niedostępny.',
                    framework_unavailable: 'Framework niedostępny.'
                };
                modalFeedback.textContent = messages[result.reason] || 'Zakup nieudany.';
                addActivityEntry(`⛔ ${state.selectedItem.label}`, false);
            }
            break;
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        if (!crateOverlay.classList.contains('hidden')) {
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
