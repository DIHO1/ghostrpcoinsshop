Config = {}

-- Framework configuration
Config.Framework = 'esx'
Config.OpenCommand = 'market'


-- Currency configuration
Config.Currency = {
    name = 'Ghost Coin',
    symbol = '💎',
    color = '#29f1ff'
}

-- Anti-spam logic for purchases
Config.AntiSpam = {
    enabled = true,
    cooldown = 5000 -- milliseconds
}

-- Shop item definitions
Config.ShopItems = {
    {
        id = 'quantum_medkit',
        label = 'Quantum Medkit',
        price = 25,
        icon = '🧬',
        description = 'Zaawansowany pakiet medyczny regenerujący zdrowie natychmiastowo.',
        rewardData = {
            type = 'item',
            item = 'medikit',
            count = 1
        }
    },
    {
        id = 'vault_cash',
        label = 'Kryptowalutowy Zastrzyk',
        price = 40,
        icon = '💼',
        description = 'Natychmiastowy zastrzyk czystej gotówki od konsorcjum Ghost.',
        rewardData = {
            type = 'money',
            account = 'money',
            amount = 50000
        }
    },
    {
        id = 'black_funds',
        label = 'Pakiet Czarnorynkowy',
        price = 55,
        icon = '🕶️',
        description = 'Płatność w brudnej gotówce dla działań w cieniu.',
        rewardData = {
            type = 'money',
            account = 'black_money',
            amount = 35000
        }
    },
    {
        id = 'ghost_overseer',
        label = 'Ranga Ghost Overseer',
        price = 75,
        icon = '👑',
        description = 'Natychmiastowy awans do elitarnej grupy administracyjnej.',
        rewardData = {
            type = 'group',
            group = 'ghost.overseer'
        }
    },
    {
        id = 'specter_proto',
        label = 'Prototyp Specter-X',
        price = 120,
        icon = '🚗',
        description = 'Limitowany pojazd klasy prototyp. Wymaga integracji z systemem garażu.',
        rewardData = {
            type = 'vehicle',
            model = 'specter',
            props = {
                colorPrimary = 12,
                colorSecondary = 120,
                neonEnabled = true
            }
        }
    }
}
