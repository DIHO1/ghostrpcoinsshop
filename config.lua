Config = {}

-- Framework configuration
Config.Framework = 'esx'
Config.OpenCommand = 'market'

-- Administrative command configuration (server side)
Config.Admin = {
    command = 'ghostcoins',
    requiredAce = 'ghostmarket.admin'
}

Config.EventTimer = {
    command = 'marketevent',
    requiredAce = 'ghostmarket.admin'
}

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

Config.Layout = {
    hero = {
        badge = 'Nowe skrzynki eventowe',
        title = 'Nowe skrzynki eventowe - ograniczone czasowo!',
        subtitle = 'Sprawdź, które pakiety znikną z oferty Ghost Market jeszcze w tym tygodniu.',
        countdown = {
            label = 'Koniec za:',
            fallback = 'Wkrótce',
            eventKey = 'hero_event'
        },
        primaryCTA = { label = 'Sprawdź skrzynki', target = 'event_crates' },
        secondaryCTA = { label = 'Kup pojazd', target = 'vehicles' },
        featuredItems = {
            'prototype_crate',
            'vehicle_crate',
            'limited_crate'
        }
    },
    sections = {
        {
            id = 'event_crates',
            title = 'Skrzynki Eventowe',
            subtitle = 'Limitowane skrzynki przygotowane specjalnie na aktualne wydarzenie.',
            filter = { category = 'event' },
            variant = 'highlight'
        },
        {
            id = 'vehicles',
            title = 'Pojazdy do kupna',
            subtitle = 'Zakup pojazd i przekaż go do swojego garażu z pomocą integracji serwera.',
            filter = { category = 'vehicles' },
            variant = 'feature'
        },
        {
            id = 'crates',
            title = 'Skrzynki',
            subtitle = 'Stała rotacja skrzynek Ghost Market z różnymi nagrodami.',
            filter = { rewardType = 'crate' },
            variant = 'grid'
        },
        {
            id = 'boosts',
            title = 'Pakiety i zasoby',
            subtitle = 'Natychmiastowe wzmocnienia, zapasy oraz premie gotówkowe.',
            filter = { category = 'boosts' },
            variant = 'grid'
        },
        {
            id = 'services',
            title = 'Usługi premium',
            subtitle = 'Odblokuj dostęp do wyjątkowych rang i dodatkowych przywilejów.',
            filter = { category = 'services' },
            variant = 'list'
        }
    }
}

-- Shop item definitions
Config.ShopItems = {
    {
        id = 'quantum_medkit',
        label = 'Quantum Medkit',
        price = 25,
        icon = '🧬',
        description = 'Zaawansowany pakiet medyczny regenerujący zdrowie natychmiastowo.',
        category = 'boosts',
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
        category = 'boosts',
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
        category = 'boosts',
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
        category = 'services',
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
        category = 'vehicles',
        rewardData = {
            type = 'vehicle',
            model = 'specter',
            props = {
                colorPrimary = 12,
                colorSecondary = 120,
                neonEnabled = true
            }
        }
    },
    {
        id = 'prototype_crate',
        label = 'Skrzynia Prototypów',
        price = 185,
        icon = '🧪',
        description = 'Eksperymentalne komponenty i konceptowe pojazdy z laboratorium Ghost.',
        category = 'event',
        rewardData = {
            type = 'crate',
            crateLabel = 'Skrzynia Prototypów',
            animation = 'prototype',
            highlight = '#62f6ff',
            pool = {
                {
                    id = 'specter_proto_crate',
                    label = 'Specter-X Prototyp',
                    icon = '🚗',
                    rarity = 'mityczny',
                    weight = 6,
                    reward = {
                        type = 'vehicle',
                        model = 'specter',
                        props = {
                            colorPrimary = 147,
                            colorSecondary = 12,
                            pearlescentColor = 111,
                            neonEnabled = true
                        }
                    }
                },
                {
                    id = 'quantum_boost',
                    label = 'Quantum Nitro',
                    icon = '⚡',
                    rarity = 'epicki',
                    weight = 14,
                    reward = {
                        type = 'item',
                        item = 'nitro',
                        count = 2
                    }
                },
                {
                    id = 'lab_cash',
                    label = 'Grant Badawczy',
                    icon = '💰',
                    rarity = 'rzadki',
                    weight = 22,
                    reward = {
                        type = 'money',
                        account = 'money',
                        amount = 75000
                    }
                },
                {
                    id = 'lab_access',
                    label = 'Dostęp Lab: Overseer',
                    icon = '🛰️',
                    rarity = 'legendarny',
                    weight = 10,
                    reward = {
                        type = 'group',
                        group = 'ghost.overseer'
                    }
                },
                {
                    id = 'prototype_supply',
                    label = 'Pakiet Materiałów',
                    icon = '📦',
                    rarity = 'niepospolity',
                    weight = 26,
                    reward = {
                        type = 'item',
                        item = 'metalscrap',
                        count = 20
                    }
                },
                {
                    id = 'prototype_tokens',
                    label = 'Żetony Ghost',
                    icon = '💎',
                    rarity = 'pospolity',
                    weight = 22,
                    reward = {
                        type = 'money',
                        account = 'money',
                        amount = 40000
                    }
                }
            }
        }
    },
    {
        id = 'vehicle_crate',
        label = 'Skrzynia Aut',
        price = 145,
        icon = '🚙',
        description = 'Pakiet pojazdów drogowych i luksusowych dodatków do garażu.',
        category = 'crates',
        rewardData = {
            type = 'crate',
            crateLabel = 'Skrzynia Aut',
            animation = 'garage',
            highlight = '#7dffb3',
            pool = {
                {
                    id = 'paragon_car',
                    label = 'Enus Paragon R',
                    icon = '🏎️',
                    rarity = 'legendarny',
                    weight = 8,
                    reward = {
                        type = 'vehicle',
                        model = 'paragon',
                        props = {
                            colorPrimary = 29,
                            colorSecondary = 111
                        }
                    }
                },
                {
                    id = 'comet_car',
                    label = 'Pfister Comet SR',
                    icon = '🚘',
                    rarity = 'epicki',
                    weight = 12,
                    reward = {
                        type = 'vehicle',
                        model = 'comet5'
                    }
                },
                {
                    id = 'drift_kit',
                    label = 'Pakiet Driftowy',
                    icon = '🛞',
                    rarity = 'rzadki',
                    weight = 20,
                    reward = {
                        type = 'item',
                        item = 'driftkit',
                        count = 1
                    }
                },
                {
                    id = 'fuel_tokens',
                    label = 'Bony Paliwowe',
                    icon = '⛽',
                    rarity = 'niepospolity',
                    weight = 25,
                    reward = {
                        type = 'item',
                        item = 'fuel',
                        count = 5
                    }
                },
                {
                    id = 'garage_cash',
                    label = 'Budżet Garażowy',
                    icon = '💵',
                    rarity = 'pospolity',
                    weight = 35,
                    reward = {
                        type = 'money',
                        account = 'money',
                        amount = 60000
                    }
                }
            }
        }
    },
    {
        id = 'pistol_crate',
        label = 'Skrzynka Arsenału',
        price = 95,
        icon = '🔫',
        description = 'Selektor krótkiej broni palnej z bonusowym wyposażeniem.',
        category = 'crates',
        rewardData = {
            type = 'crate',
            crateLabel = 'Skrzynka Arsenału',
            animation = 'arsenal',
            highlight = '#ff9f68',
            pool = {
                {
                    id = 'pistol_mk2',
                    label = 'Pistolet MK II',
                    icon = '🔧',
                    rarity = 'epicki',
                    weight = 12,
                    reward = {
                        type = 'weapon',
                        weapon = 'weapon_pistol_mk2',
                        ammo = 160
                    }
                },
                {
                    id = 'heavy_pistol',
                    label = 'Ciężki Pistolet',
                    icon = '💥',
                    rarity = 'rzadki',
                    weight = 18,
                    reward = {
                        type = 'weapon',
                        weapon = 'weapon_heavypistol',
                        ammo = 120
                    }
                },
                {
                    id = 'sns_pistol',
                    label = 'Pistolet SNS',
                    icon = '🕵️',
                    rarity = 'niepospolity',
                    weight = 26,
                    reward = {
                        type = 'weapon',
                        weapon = 'weapon_snspistol',
                        ammo = 80
                    }
                },
                {
                    id = 'ammo_pack',
                    label = 'Pakiet Amunicji',
                    icon = '🎯',
                    rarity = 'pospolity',
                    weight = 24,
                    reward = {
                        type = 'item',
                        item = 'ammo-9mm',
                        count = 50
                    }
                },
                {
                    id = 'weapon_tokens',
                    label = 'Token Szkoleniowy',
                    icon = '🎖️',
                    rarity = 'legendarny',
                    weight = 10,
                    reward = {
                        type = 'group',
                        group = 'ghost.weapons'
                    }
                }
            }
        }
    },
    {
        id = 'limited_crate',
        label = 'Skrzynia Limitek',
        price = 210,
        icon = '🎁',
        description = 'Ekskluzywne nagrody limitowane czasowo i kolekcjonerskie.',
        category = 'event',
        rewardData = {
            type = 'crate',
            crateLabel = 'Skrzynia Limitek',
            animation = 'limited',
            highlight = '#f86bff',
            pool = {
                {
                    id = 'ghost_suit',
                    label = 'Kombinezon Ghost Prime',
                    icon = '🧥',
                    rarity = 'mityczny',
                    weight = 8,
                    reward = {
                        type = 'item',
                        item = 'ghost_suit',
                        count = 1
                    }
                },
                {
                    id = 'ghost_vip',
                    label = 'Przepustka VIP',
                    icon = '💳',
                    rarity = 'legendarny',
                    weight = 12,
                    reward = {
                        type = 'group',
                        group = 'ghost.vip'
                    }
                },
                {
                    id = 'ghost_coin_cache',
                    label = 'Skarbiec Ghost Coins',
                    icon = '💎',
                    rarity = 'epicki',
                    weight = 18,
                    reward = {
                        type = 'money',
                        account = 'money',
                        amount = 120000
                    }
                },
                {
                    id = 'exclusive_vehicle',
                    label = 'Elegy Retro Custom',
                    icon = '🚘',
                    rarity = 'rzadki',
                    weight = 16,
                    reward = {
                        type = 'vehicle',
                        model = 'elegy',
                        props = {
                            colorPrimary = 145,
                            colorSecondary = 13,
                            neonEnabled = true
                        }
                    }
                },
                {
                    id = 'limited_art',
                    label = 'Holograficzny Obraz',
                    icon = '🖼️',
                    rarity = 'niepospolity',
                    weight = 22,
                    reward = {
                        type = 'item',
                        item = 'art_holo',
                        count = 1
                    }
                },
                {
                    id = 'limited_tokens',
                    label = 'Token Eventowy',
                    icon = '🎟️',
                    rarity = 'pospolity',
                    weight = 24,
                    reward = {
                        type = 'item',
                        item = 'event_token',
                        count = 3
                    }
                }
            }
        }
    }
}
