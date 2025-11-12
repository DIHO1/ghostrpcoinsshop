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

-- Hero + section layout metadata for the tablet storefront
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
            'specter_proto',
            'limited_crate'
        }
    },
    sections = {}
}

-- Catalog definitions grouped by storefront section
Config.Catalog = {
    {
        key = 'event',
        section = {
            id = 'event_crates',
            title = 'Skrzynki Eventowe',
            subtitle = 'Limitowane skrzynki przygotowane specjalnie na aktualne wydarzenie.',
            variant = 'highlight',
            filter = { category = 'event' }
        },
        items = {
            {
                id = 'prototype_crate',
                label = 'Skrzynia Prototypów',
                price = 185,
                icon = '🧪',
                description = 'Eksperymentalne komponenty i konceptowe pojazdy z laboratorium Ghost.',
                visual = {
                    type = 'crate',
                    icon = '🧪',
                    accent = '#62f6ff',
                    label = 'Prototypy',
                    tagline = 'Laboratoryjne projekty Ghost',
                    image = 'images/props/item_nitro.svg'
                },
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
                            prop = {
                                icon = '🚗',
                                color = '#62f6ff',
                                image = 'images/props/vehicle_specter.svg'
                            },
                            reward = {
                                type = 'vehicle',
                                model = 'specter',
                                displayName = 'Specter-X',
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
                            prop = {
                                icon = '⚡',
                                color = '#ae74ff',
                                image = 'images/props/item_nitro.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'nitro',
                                count = 2,
                                displayName = 'Quantum Nitro'
                            }
                        },
                        {
                            id = 'lab_cash',
                            label = 'Grant Badawczy',
                            icon = '💰',
                            rarity = 'rzadki',
                            weight = 22,
                            prop = {
                                icon = '💰',
                                color = '#ffd66b',
                                image = 'images/props/cash_grant.svg'
                            },
                            reward = {
                                type = 'money',
                                account = 'money',
                                amount = 75000,
                                displayName = '75 000$ grant'
                            }
                        },
                        {
                            id = 'lab_access',
                            label = 'Dostęp Lab: Overseer',
                            icon = '🛰️',
                            rarity = 'legendarny',
                            weight = 10,
                            prop = {
                                icon = '🛰️',
                                color = '#6afff2',
                                image = 'images/props/group_overseer.svg'
                            },
                            reward = {
                                type = 'group',
                                group = 'ghost.overseer',
                                displayName = 'Uprawnienia Overseer'
                            }
                        },
                        {
                            id = 'prototype_supply',
                            label = 'Pakiet Materiałów',
                            icon = '📦',
                            rarity = 'niepospolity',
                            weight = 26,
                            prop = {
                                icon = '📦',
                                color = '#6da9ff',
                                image = 'images/props/item_materials.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'metalscrap',
                                count = 20,
                                displayName = 'Pakiet materiałów'
                            }
                        },
                        {
                            id = 'prototype_tokens',
                            label = 'Żetony Ghost',
                            icon = '💎',
                            rarity = 'pospolity',
                            weight = 22,
                            prop = {
                                icon = '💎',
                                color = '#29f1ff',
                                image = 'images/props/cash_tokens.svg'
                            },
                            reward = {
                                type = 'money',
                                account = 'money',
                                amount = 40000,
                                displayName = '40 000$ Ghost'
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
                visual = {
                    type = 'crate',
                    icon = '🎁',
                    accent = '#f86bff',
                    label = 'Limitki',
                    tagline = 'Limitowane kolekcje',
                    image = 'images/props/item_ghost_suit.svg'
                },
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
                            prop = {
                                icon = '🧥',
                                color = '#f86bff',
                                image = 'images/props/item_ghost_suit.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'ghost_suit',
                                count = 1,
                                displayName = 'Kombinezon Ghost Prime'
                            }
                        },
                        {
                            id = 'ghost_vip',
                            label = 'Przepustka VIP',
                            icon = '💳',
                            rarity = 'legendarny',
                            weight = 12,
                            prop = {
                                icon = '💳',
                                color = '#7dffb3',
                                image = 'images/props/group_vip.svg'
                            },
                            reward = {
                                type = 'group',
                                group = 'ghost.vip',
                                displayName = 'Ranga VIP'
                            }
                        },
                        {
                            id = 'ghost_coin_cache',
                            label = 'Skarbiec Ghost Coins',
                            icon = '💎',
                            rarity = 'epicki',
                            weight = 18,
                            prop = {
                                icon = '💎',
                                color = '#29f1ff',
                                image = 'images/props/cash_cache.svg'
                            },
                            reward = {
                                type = 'money',
                                account = 'money',
                                amount = 120000,
                                displayName = '120 000$ Ghost'
                            }
                        },
                        {
                            id = 'exclusive_vehicle',
                            label = 'Elegy Retro Custom',
                            icon = '🚘',
                            rarity = 'rzadki',
                            weight = 16,
                            prop = {
                                icon = '🚘',
                                color = '#62f6ff',
                                image = 'images/props/vehicle_elegy.svg'
                            },
                            reward = {
                                type = 'vehicle',
                                model = 'elegy',
                                displayName = 'Elegy Retro Custom',
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
                            prop = {
                                icon = '🖼️',
                                color = '#ffb76b',
                                image = 'images/props/item_holo_art.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'art_holo',
                                count = 1,
                                displayName = 'Holograficzny obraz'
                            }
                        },
                        {
                            id = 'limited_tokens',
                            label = 'Token Eventowy',
                            icon = '🎟️',
                            rarity = 'pospolity',
                            weight = 24,
                            prop = {
                                icon = '🎟️',
                                color = '#8e9cff',
                                image = 'images/props/item_event_token.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'event_token',
                                count = 3,
                                displayName = 'Token Eventowy'
                            }
                        }
                    }
                }
            }
        }
    },
    {
        key = 'vehicles',
        section = {
            id = 'vehicles',
            title = 'Pojazdy do kupna',
            subtitle = 'Zakup pojazd i przekaż go do swojego garażu z pomocą integracji serwera.',
            variant = 'feature',
            filter = { category = 'vehicles' }
        },
        items = {
            {
                id = 'specter_proto',
                label = 'Prototyp Specter-X',
                price = 120,
                icon = '🚗',
                description = 'Limitowany pojazd klasy prototyp. Wymaga integracji z systemem garażu.',
                visual = {
                    type = 'vehicle',
                    name = 'Specter-X',
                    model = 'specter',
                    accent = '#62f6ff',
                    tagline = 'Prototyp klasy X',
                    image = 'images/props/vehicle_specter.svg'
                },
                rewardData = {
                    type = 'vehicle',
                    model = 'specter',
                    displayName = 'Specter-X',
                    props = {
                        colorPrimary = 12,
                        colorSecondary = 120,
                        neonEnabled = true
                    }
                }
            },
            {
                id = 'paragon_signature',
                label = 'Enus Paragon R',
                price = 145,
                icon = '🏎️',
                description = 'Uliczny supersamochód w pakiecie VIP z gotowym wykończeniem.',
                visual = {
                    type = 'vehicle',
                    name = 'Paragon R',
                    model = 'paragon',
                    accent = '#7dffb3',
                    tagline = 'Supersamochód klasy premium',
                    image = 'images/props/vehicle_paragon.svg'
                },
                rewardData = {
                    type = 'vehicle',
                    model = 'paragon',
                    displayName = 'Paragon R',
                    props = {
                        colorPrimary = 29,
                        colorSecondary = 111
                    }
                }
            }
        }
    },
    {
        key = 'crates',
        section = {
            id = 'crates',
            title = 'Skrzynki Specjalne',
            subtitle = 'Stała rotacja skrzynek Ghost Market z różnymi nagrodami.',
            variant = 'grid',
            filter = { category = 'crates' }
        },
        items = {
            {
                id = 'vehicle_crate',
                label = 'Skrzynia Aut',
                price = 145,
                icon = '🚙',
                description = 'Pakiet pojazdów drogowych i luksusowych dodatków do garażu.',
                visual = {
                    type = 'crate',
                    icon = '🚙',
                    accent = '#7dffb3',
                    label = 'Pojazdy',
                    tagline = 'Losowe nagrody garażowe',
                    image = 'images/props/vehicle_paragon.svg'
                },
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
                            prop = {
                                icon = '🏎️',
                                color = '#7dffb3',
                                image = 'images/props/vehicle_paragon.svg'
                            },
                            reward = {
                                type = 'vehicle',
                                model = 'paragon',
                                displayName = 'Paragon R'
                            }
                        },
                        {
                            id = 'comet_car',
                            label = 'Pfister Comet SR',
                            icon = '🚘',
                            rarity = 'epicki',
                            weight = 12,
                            prop = {
                                icon = '🚘',
                                color = '#62d4ff',
                                image = 'images/props/vehicle_comet.svg'
                            },
                            reward = {
                                type = 'vehicle',
                                model = 'comet5',
                                displayName = 'Comet SR'
                            }
                        },
                        {
                            id = 'drift_kit',
                            label = 'Pakiet Driftowy',
                            icon = '🛞',
                            rarity = 'rzadki',
                            weight = 20,
                            prop = {
                                icon = '🛞',
                                color = '#ffcf6d',
                                image = 'images/props/item_drift_kit.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'driftkit',
                                count = 1,
                                displayName = 'Zestaw driftowy'
                            }
                        },
                        {
                            id = 'fuel_tokens',
                            label = 'Bony Paliwowe',
                            icon = '⛽',
                            rarity = 'niepospolity',
                            weight = 25,
                            prop = {
                                icon = '⛽',
                                color = '#7aa9ff',
                                image = 'images/props/item_fuel.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'fuel',
                                count = 5,
                                displayName = 'Bony paliwowe'
                            }
                        },
                        {
                            id = 'garage_cash',
                            label = 'Budżet Garażowy',
                            icon = '💵',
                            rarity = 'pospolity',
                            weight = 35,
                            prop = {
                                icon = '💵',
                                color = '#7cffd7',
                                image = 'images/props/cash_garage.svg'
                            },
                            reward = {
                                type = 'money',
                                account = 'money',
                                amount = 60000,
                                displayName = '60 000$ garaż'
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
                visual = {
                    type = 'crate',
                    icon = '🔫',
                    accent = '#ff9f68',
                    label = 'Arsenał',
                    tagline = 'Broń i ulepszenia',
                    image = 'images/props/weapon_pistol_mk2.svg'
                },
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
                            prop = {
                                icon = '🔧',
                                color = '#ff9f68',
                                image = 'images/props/weapon_pistol_mk2.svg'
                            },
                            reward = {
                                type = 'weapon',
                                weapon = 'weapon_pistol_mk2',
                                ammo = 160,
                                displayName = 'Pistolet MK II'
                            }
                        },
                        {
                            id = 'heavy_pistol',
                            label = 'Ciężki Pistolet',
                            icon = '💥',
                            rarity = 'rzadki',
                            weight = 18,
                            prop = {
                                icon = '💥',
                                color = '#ffc86b',
                                image = 'images/props/weapon_heavypistol.svg'
                            },
                            reward = {
                                type = 'weapon',
                                weapon = 'weapon_heavypistol',
                                ammo = 120,
                                displayName = 'Heavy Pistol'
                            }
                        },
                        {
                            id = 'sns_pistol',
                            label = 'Pistolet SNS',
                            icon = '🕵️',
                            rarity = 'niepospolity',
                            weight = 26,
                            prop = {
                                icon = '🕵️',
                                color = '#9c8cff',
                                image = 'images/props/weapon_snspistol.svg'
                            },
                            reward = {
                                type = 'weapon',
                                weapon = 'weapon_snspistol',
                                ammo = 80,
                                displayName = 'SNS Pistol'
                            }
                        },
                        {
                            id = 'ammo_pack',
                            label = 'Pakiet Amunicji',
                            icon = '🎯',
                            rarity = 'pospolity',
                            weight = 24,
                            prop = {
                                icon = '🎯',
                                color = '#6da9ff',
                                image = 'images/props/item_ammo.svg'
                            },
                            reward = {
                                type = 'item',
                                item = 'ammo-9mm',
                                count = 50,
                                displayName = 'Amunicja 9mm'
                            }
                        },
                        {
                            id = 'weapon_tokens',
                            label = 'Token Szkoleniowy',
                            icon = '🎖️',
                            rarity = 'legendarny',
                            weight = 10,
                            prop = {
                                icon = '🎖️',
                                color = '#ff6db8',
                                image = 'images/props/group_weapon.svg'
                            },
                            reward = {
                                type = 'group',
                                group = 'ghost.weapons',
                                displayName = 'Uprawnienia bojowe'
                            }
                        }
                    }
                }
            }
        }
    },
    {
        key = 'boosts',
        section = {
            id = 'boosts',
            title = 'Pakiety i zasoby',
            subtitle = 'Natychmiastowe wzmocnienia, zapasy oraz premie gotówkowe.',
            variant = 'grid',
            filter = { category = 'boosts' }
        },
        items = {
            {
                id = 'quantum_medkit',
                label = 'Quantum Medkit',
                price = 25,
                icon = '🧬',
                description = 'Zaawansowany pakiet medyczny regenerujący zdrowie natychmiastowo.',
                visual = {
                    type = 'boost',
                    icon = '🧬',
                    accent = '#9c8cff',
                    label = 'Medyczne wsparcie',
                    tagline = 'Natychmiastowa regeneracja'
                },
                rewardData = {
                    type = 'item',
                    item = 'medikit',
                    count = 1,
                    displayName = 'Quantum Medkit'
                }
            },
            {
                id = 'vault_cash',
                label = 'Kryptowalutowy Zastrzyk',
                price = 40,
                icon = '💼',
                description = 'Natychmiastowy zastrzyk czystej gotówki od konsorcjum Ghost.',
                visual = {
                    type = 'boost',
                    icon = '💼',
                    accent = '#29f1ff',
                    label = 'Czysta gotówka',
                    tagline = 'Bezpośrednia wypłata'
                },
                rewardData = {
                    type = 'money',
                    account = 'money',
                    amount = 50000,
                    displayName = '50 000$ gotówki'
                }
            },
            {
                id = 'black_funds',
                label = 'Pakiet Czarnorynkowy',
                price = 55,
                icon = '🕶️',
                description = 'Płatność w brudnej gotówce dla działań w cieniu.',
                visual = {
                    type = 'boost',
                    icon = '🕶️',
                    accent = '#ff6db8',
                    label = 'Brudna gotówka',
                    tagline = 'Operacje specjalne'
                },
                rewardData = {
                    type = 'money',
                    account = 'black_money',
                    amount = 35000,
                    displayName = '35 000$ brudnej gotówki'
                }
            }
        }
    },
    {
        key = 'services',
        section = {
            id = 'services',
            title = 'Usługi premium',
            subtitle = 'Odblokuj dostęp do wyjątkowych rang i dodatkowych przywilejów.',
            variant = 'list',
            filter = { category = 'services' }
        },
        items = {
            {
                id = 'ghost_overseer',
                label = 'Ranga Ghost Overseer',
                price = 75,
                icon = '👑',
                description = 'Natychmiastowy awans do elitarnej grupy administracyjnej.',
                visual = {
                    type = 'service',
                    icon = '👑',
                    accent = '#ffd66b',
                    label = 'Ranga administracyjna'
                },
                rewardData = {
                    type = 'group',
                    group = 'ghost.overseer',
                    displayName = 'Ranga Ghost Overseer'
                }
            }
        }
    }
}

-- Helper to deep copy configuration tables
local function deepCopy(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, val in pairs(value) do
        copy[key] = deepCopy(val)
    end

    return copy
end

Config.ShopItems = {}

for _, catalog in ipairs(Config.Catalog) do
    local section = deepCopy(catalog.section or {})
    section.id = section.id or catalog.key
    section.filter = section.filter or { category = catalog.key }
    section.filter.category = section.filter.category or catalog.key
    table.insert(Config.Layout.sections, section)

    for _, item in ipairs(catalog.items or {}) do
        local entry = deepCopy(item)
        entry.category = catalog.key
        table.insert(Config.ShopItems, entry)
    end
end
