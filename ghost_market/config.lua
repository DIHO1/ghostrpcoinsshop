Config = {}

-- Framework & Command Configuration
Config.Framework = 'ESX' -- Framework (ESX is supported)
Config.OpenCommand = 'market' -- Command to open the Ghost Market

-- Premium Currency Configuration
Config.Currency = {
    name = 'Ghost Coins',
    symbol = '💎',
    color = '#00FFFF' -- Neon/Cyberpunk color for the currency symbol
}

-- Anti-Spam Logic
Config.EnableAntiSpam = true -- Set to true to prevent purchase spamming
Config.AntiSpamDelay = 2000 -- Cooldown in milliseconds (2 seconds)

-- Shop Items Definition
Config.ShopItems = {
    {
        label = 'Zestaw Medyczny',
        price = 50,
        description = 'Pakiet 5 apteczek, aby szybko wrócić do zdrowia.',
        image = 'https://i.imgur.com/J4p7aX2.png',
        rewardData = {
            type = 'item',
            name = 'medkit',
            amount = 5
        }
    },
    {
        label = 'Dotacja Gotówkowa',
        price = 100,
        description = 'Natychmiastowy zastrzyk 25,000$ czystej gotówki na Twoje konto.',
        image = 'https://i.imgur.com/ZoDAA3a.png',
        rewardData = {
            type = 'money',
            account = 'money', -- 'money', 'black_money', 'bank'
            amount = 25000
        }
    },
    {
        label = 'Status VIP',
        price = 500,
        description = 'Nadaje permanentny status VIP, odblokowując specjalne korzyści.',
        image = 'https://i.imgur.com/tL42a2A.png',
        rewardData = {
            type = 'group',
            name = 'vip' -- The name of the group/permission to grant
        }
    },
    {
        label = 'Super Samochód',
        price = 1200,
        description = 'Odbierz kluczyki do legendarnego Pegassi Zentorno.',
        image = 'https://i.imgur.com/f2IgG1D.png',
        rewardData = {
            type = 'vehicle',
            model = 'zentorno',
            plate = 'GHOST' -- Optional: set a custom plate
        }
    },
    {
        label = 'Tajemnicza Skrzynia',
        price = 250,
        description = 'Zawiera losowy, rzadki przedmiot. Co znajdziesz w środku?',
        image = 'https://i.imgur.com/sT5b2j0.png',
        rewardData = {
            type = 'item',
            name = 'mystery_box',
            amount = 1
        }
    }
}
