document.addEventListener('DOMContentLoaded', () => {
    const container = document.querySelector('.main-container');
    const itemsGrid = document.getElementById('items-grid');
    const balanceDisplay = document.getElementById('balance');
    const currencySymbolDisplay = document.getElementById('currency-symbol');
    const closeBtn = document.getElementById('close-btn');

    // Modal elements
    const modal = document.getElementById('confirmation-modal');
    const modalText = document.getElementById('modal-text');
    const confirmBtn = document.getElementById('confirm-purchase-btn');
    const cancelBtn = document.getElementById('cancel-purchase-btn');

    let currentItem = null;
    let currentBalance = 0;
    let currencyInfo = {};
    let resourceName = 'ghost_market'; // Default resource name, will be updated

    // =============================================================================
    // NUI Communication
    // =============================================================================

    const post = (event, data = {}) => {
        fetch(`https://${resourceName}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(e => console.error(`Error posting to ${event}:`, e));
    };

    // Listen for messages from the client script
    window.addEventListener('message', (event) => {
        const { action, ...data } = event.data;
        switch (action) {
            case 'setVisible':
                container.style.display = data.status ? 'flex' : 'none';
                break;
            case 'initialize':
                resourceName = data.resourceName; // Update the resource name
                currencyInfo = data.currency;
                updateBalance(data.balance);
                populateItems(data.items);
                currencySymbolDisplay.textContent = currencyInfo.symbol;
                currencySymbolDisplay.style.color = currencyInfo.color;
                break;
            case 'updateBalance':
                updateBalance(data.balance);
                break;
        }
    });

    // =============================================================================
    // UI Logic
    // =============================================================================

    const updateBalance = (balance) => {
        currentBalance = balance;
        balanceDisplay.textContent = balance.toLocaleString();
    };

    const populateItems = (items) => {
        itemsGrid.innerHTML = ''; // Clear existing items
        items.forEach((item, index) => {
            const card = document.createElement('div');
            card.className = 'item-card';
            card.dataset.index = index;

            card.innerHTML = `
                <img src="${item.image}" class="item-image" alt="${item.label}">
                <div class="item-details">
                    <h3 class="item-label">${item.label}</h3>
                    <p class="item-description">${item.description}</p>
                    <div class="item-price">
                        <span>${item.price.toLocaleString()}</span>
                        <span style="color: ${currencyInfo.color || '#00FFFF'};">${currencyInfo.symbol || '💎'}</span>
                    </div>
                </div>
            `;

            // Add click listener to open confirmation modal
            card.addEventListener('click', () => {
                if (currentBalance >= item.price) {
                    currentItem = { ...item, index };
                    openModal(item);
                } else {
                    // Optionally, add a visual indicator for insufficient funds
                    card.style.animation = 'shake 0.5s';
                    setTimeout(() => card.style.animation = '', 500);
                }
            });
            itemsGrid.appendChild(card);
        });
    };

    // =============================================================================
    // Modal Logic
    // =============================================================================

    const openModal = (item) => {
        modalText.innerHTML = `Czy na pewno chcesz kupić <strong>${item.label}</strong> za <strong>${item.price.toLocaleString()} ${currencyInfo.symbol}</strong>?`;
        modal.style.display = 'flex';
    };

    const closeModal = () => {
        modal.style.display = 'none';
        currentItem = null;
    };

    confirmBtn.addEventListener('click', () => {
        if (currentItem) {
            post('purchaseItem', { itemIndex: currentItem.index + 1 }); // Lua is 1-based
            closeModal();
        }
    });

    cancelBtn.addEventListener('click', closeModal);

    // Close NUI
    closeBtn.addEventListener('click', () => post('closeNui'));
});
