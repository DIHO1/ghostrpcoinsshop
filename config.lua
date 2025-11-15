Config = {}

Config.Locale = 'pl'
Config.Debug = false

Config.Commands = {
    market = 'sklep',
    admin = 'ghostcoins',
    event = 'marketevent'
}

Config.Keybind = {
    enabled = true,
    key = 'F7',
    command = 'ghostmarket:tablet',
    description = 'Otwórz tablet Ghost Market'
}

Config.Currency = {
    label = 'Ghost Coin',
    short = 'GC',
    icon = '👻',
    color = '#6c5ce7',
    gradient = {'#6c5ce7', '#00d2d3'}
}

Config.Database = {
    walletTable = 'ghost_shop_wallet',
    eventTable = 'ghost_shop_state',
    logTable = 'ghost_shop_log'
}

Config.Admin = {
    requiredAce = 'ghostmarket.admin'
}

Config.EventTimer = {
    enabled = true,
    requiredAce = 'ghostmarket.admin'
}

Config.Cooldowns = {
    purchase = 3, -- sekundy
    reopen = 1
}

Config.Hero = {
    title = 'Kosmiczne oferty',
    subtitle = 'Odbierz codzienny bonus i zgarnij limitowane paczki',
    background = 'linear-gradient(135deg, rgba(108,92,231,0.45), rgba(0,210,211,0.45))',
    video = '',
    badge = {
        text = 'Nowość',
        color = '#ff7675'
    }
}

Config.Layout = {
    featured = {
        {
            id = 'starter-pack',
            item = 'bundle',
            title = 'Paczka Startowa',
            description = '5x Apteczka + 10 000$ gotówki + strój premium',
            price = 249,
            ribbon = 'Polecane',
            image = 'linear-gradient(135deg, #fc5c7d, #6a82fb)'
        },
        {
            id = 'vip-pass',
            item = 'service',
            title = 'VIP Pass 7 dni',
            description = 'Dostęp do ekskluzywnych pojazdów i boost XP',
            price = 549,
            ribbon = 'Limitowane',
            image = 'linear-gradient(135deg, #00d2ff, #3a7bd5)'
        }
    },
    categories = {
        {
            id = 'boosts',
            label = 'Boosty',
            icon = 'bolt',
            items = {'double-xp', 'drug-boost', 'priority-queue'}
        },
        {
            id = 'vehicles',
            label = 'Pojazdy',
            icon = 'car',
            items = {'veh-cypher', 'veh-jester', 'veh-stromberg'}
        },
        {
            id = 'crates',
            label = 'Skrzynki',
            icon = 'box',
            items = {'crate-legendary', 'crate-street'}
        },
        {
            id = 'services',
            label = 'Usługi',
            icon = 'crown',
            items = {'name-change', 'gang-slot'}
        }
    }
}

Config.ShopItems = {
    ['starter-pack'] = {
        label = 'Paczka Startowa',
        description = '5x Apteczka + 10 000$ gotówki + strój premium.',
        price = 249,
        type = 'bundle',
        reward = {
            type = 'bundle',
            data = {
                { type = 'item', data = { item = 'medikit', count = 5 } },
                { type = 'money', data = { account = 'money', amount = 10000 } },
                { type = 'event', data = { event = 'ghostmarket:giveOutfit', outfit = 'starter_pack' } }
            }
        }
    },
    ['vip-pass'] = {
        label = 'VIP Pass 7 dni',
        description = 'Nadaje rangę VIP na 7 dni wraz z bonusami.',
        price = 549,
        type = 'service',
        reward = {
            type = 'group',
            data = { group = 'vip', duration = 7 * 24 * 60 }
        }
    },
    ['double-xp'] = {
        label = 'Podwójne doświadczenie 60 min',
        description = 'x2 doświadczenie dla wszystkich aktywności przez godzinę.',
        price = 199,
        type = 'service',
        reward = {
            type = 'event',
            data = {event = 'ghostmarket:activateDoubleXP', duration = 60}
        }
    },
    ['drug-boost'] = {
        label = 'Booster narkotyków',
        description = 'Zwiększa zyski ze sprzedaży o 25% na 45 min.',
        price = 149,
        type = 'service',
        reward = {
            type = 'event',
            data = {event = 'ghostmarket:activateDrugBoost', duration = 45}
        }
    },
    ['priority-queue'] = {
        label = 'Priorytet w kolejce',
        description = 'Umieszcza Cię na szczycie kolejki oczekujących na serwer.',
        price = 399,
        type = 'service',
        reward = {
            type = 'group',
            data = {group = 'priority', duration = 7 * 24 * 60}
        }
    },
    ['veh-cypher'] = {
        label = 'Übermacht Cypher',
        description = 'Sportowe coupe dostępne od ręki.',
        price = 1199,
        type = 'vehicle',
        reward = {
            type = 'vehicle',
            data = {model = 'cypher', garage = 'premium'}
        }
    },
    ['veh-jester'] = {
        label = 'Dinka Jester RR',
        description = 'Pakiet driftowy + tunning wizualny.',
        price = 1499,
        type = 'vehicle',
        reward = {
            type = 'vehicle',
            data = {model = 'jester4', garage = 'premium'}
        }
    },
    ['veh-stromberg'] = {
        label = 'Ocelot Stromberg',
        description = 'Egzotyczny pojazd amfibii do zadań specjalnych.',
        price = 2499,
        type = 'vehicle',
        reward = {
            type = 'vehicle',
            data = {model = 'stromberg', garage = 'premium'}
        }
    },
    ['crate-legendary'] = {
        label = 'Skrzynka Legendarna',
        description = 'Zawiera gwarantowany przedmiot legendarny.',
        price = 799,
        type = 'crate',
        reward = {
            type = 'crate',
            data = {
                animation = 'legendary',
                rolls = {
                    {id = 'veh-cypher', weight = 15},
                    {id = 'veh-jester', weight = 10},
                    {id = 'veh-stromberg', weight = 5},
                    {id = 'double-xp', weight = 20},
                    {id = 'drug-boost', weight = 20},
                    {id = 'priority-queue', weight = 30}
                }
            }
        }
    },
    ['crate-street'] = {
        label = 'Skrzynka Street',
        description = 'Stylowe samochody i boosty gangowe.',
        price = 499,
        type = 'crate',
        reward = {
            type = 'crate',
            data = {
                animation = 'street',
                rolls = {
                    {id = 'veh-cypher', weight = 20},
                    {id = 'veh-jester', weight = 15},
                    {id = 'double-xp', weight = 30},
                    {id = 'drug-boost', weight = 35}
                }
            }
        }
    },
    ['name-change'] = {
        label = 'Zmiana imienia',
        description = 'Jednorazowa zmiana danych postaci u administracji.',
        price = 299,
        type = 'service',
        reward = {
            type = 'ticket',
            data = {category = 'support', subject = 'Zmiana imienia'}
        }
    },
    ['gang-slot'] = {
        label = 'Slot dla gangu',
        description = 'Odblokowuje dodatkowe miejsce dla członka gangu.',
        price = 899,
        type = 'service',
        reward = {
            type = 'group',
            data = {group = 'gangplus', duration = 30 * 24 * 60}
        }
    }
}

Config.ActivityFeed = {
    enabled = true,
    maxEntries = 15,
    useDatabase = true
}

Config.Notification = {
    success = function(source, message)
        TriggerClientEvent('esx:showNotification', source, message)
    end,
    error = function(source, message)
        TriggerClientEvent('esx:showNotification', source, message)
    end
}

Config.LocalePhrases = {
    tabletTitle = 'Ghost Market',
    balanceLabel = 'Saldo',
    buyButton = 'Zakup',
    confirmTitle = 'Potwierdź zakup',
    confirmDescription = 'Czy na pewno chcesz kupić ten produkt?',
    cancel = 'Anuluj',
    confirm = 'Potwierdź',
    history = 'Ostatnia aktywność',
    heroTimer = 'Wydarzenie kończy się za'
}
