const state = {
    items: [],
    currency: { symbol: '💎', name: 'Ghost Coin' },
    selectedItem: null,
    wallet: 0,
    activeView: 'overview',
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
