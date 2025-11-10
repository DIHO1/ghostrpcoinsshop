const state = {
    items: [],
    currency: { symbol: '💎', name: 'Ghost Coin' },
    selectedItem: null,
    wallet: 0
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
            renderItems();
            setWallet(state.wallet);
            break;
        case 'close':
            app.classList.add('hidden');
            closeModal();
            document.body.classList.remove('market-active');
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
