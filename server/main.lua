local ESX = exports['es_extended']:getSharedObject()

local purchaseCooldown = {}
local reopenCooldown = {}
local cachedConfig

local function debugPrint(...)
    if Config.Debug then
        print('[GhostMarket]', ...)
    end
end

local function ensureTables()
    local walletTable = Config.Database.walletTable
    local eventTable = Config.Database.eventTable
    local logTable = Config.Database.logTable

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        identifier VARCHAR(64) NOT NULL PRIMARY KEY,
        balance INT NOT NULL DEFAULT 0,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]]):format(walletTable))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        name VARCHAR(32) NOT NULL PRIMARY KEY,
        value TEXT,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )]]):format(eventTable))

    MySQL.query.await(([[CREATE TABLE IF NOT EXISTS %s (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        identifier VARCHAR(64) NOT NULL,
        item_id VARCHAR(64) NOT NULL,
        amount INT NOT NULL,
        price INT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )]]):format(logTable))
end

local function getPlayerIdentifier(xPlayer)
    if xPlayer then
        return xPlayer.identifier or xPlayer.getIdentifier()
    end
end

local function ensureWallet(identifier)
    local row = MySQL.single.await(('SELECT balance FROM %s WHERE identifier = ?'):format(Config.Database.walletTable), {identifier})
    if not row then
        MySQL.insert.await(('INSERT INTO %s (identifier, balance) VALUES (?, 0)'):format(Config.Database.walletTable), {identifier})
        return 0
    end
    return row.balance
end

local function getBalance(identifier)
    local row = MySQL.single.await(('SELECT balance FROM %s WHERE identifier = ?'):format(Config.Database.walletTable), {identifier})
    if row then
        return row.balance
    end
    return ensureWallet(identifier)
end

local function setBalance(identifier, amount)
    MySQL.update.await(('UPDATE %s SET balance = ? WHERE identifier = ?'):format(Config.Database.walletTable), {amount, identifier})
end

local function addBalance(identifier, amount)
    local current = getBalance(identifier)
    local newBalance = math.max(0, current + amount)
    setBalance(identifier, newBalance)
    return newBalance
end

local function recordActivity(identifier, itemId, amount, price)
    if not Config.ActivityFeed.enabled then
        return
    end

    if Config.ActivityFeed.useDatabase then
        MySQL.insert.await(('INSERT INTO %s (identifier, item_id, amount, price) VALUES (?, ?, ?, ?)'):format(Config.Database.logTable), {
            identifier,
            itemId,
            amount,
            price
        })
    end
end

local function fetchActivity()
    if not Config.ActivityFeed.enabled then
        return {}
    end

    if not Config.ActivityFeed.useDatabase then
        return {}
    end

    local rows = MySQL.query.await(([[SELECT id, identifier, item_id, price, created_at
        FROM %s
        ORDER BY id DESC
        LIMIT ?]]):format(Config.Database.logTable), {
        Config.ActivityFeed.maxEntries or 15
    })

    return rows or {}
end

local function getEventState()
    if not Config.EventTimer.enabled then
        return nil
    end

    local row = MySQL.single.await(('SELECT value FROM %s WHERE name = ?'):format(Config.Database.eventTable), {'event_timer'})
    if row and row.value and row.value ~= '' then
        local decoded = json.decode(row.value)
        return decoded
    end

    return nil
end

local function setEventState(data)
    if not Config.EventTimer.enabled then
        return
    end

    if data == nil then
        MySQL.update.await(([[DELETE FROM %s WHERE name = ?]]):format(Config.Database.eventTable), {'event_timer'})
        return
    end

    local encoded = json.encode(data)
    MySQL.insert.await(([[INSERT INTO %s (name, value) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE value = VALUES(value)]]):format(Config.Database.eventTable), {'event_timer', encoded})
end

local function sanitizeItems()
    if cachedConfig then
        return cachedConfig
    end

    local layoutItems = {}
    for itemId, data in pairs(Config.ShopItems) do
        layoutItems[itemId] = {
            label = data.label,
            description = data.description,
            price = data.price,
            type = data.type,
            reward = data.reward,
            image = data.image,
            ribbon = data.ribbon
        }
    end

    cachedConfig = {
        locale = Config.Locale,
        currency = Config.Currency,
        hero = Config.Hero,
        layout = Config.Layout,
        items = layoutItems,
        phrases = Config.LocalePhrases,
        activity = {
            enabled = Config.ActivityFeed.enabled
        }
    }

    return cachedConfig
end

local function checkCooldown(cooldowns, source, limit)
    local now = GetGameTimer()
    local last = cooldowns[source] or 0
    if now - last < limit * 1000 then
        return false, (limit * 1000 - (now - last)) / 1000
    end
    cooldowns[source] = now
    return true
end

local function grantReward(source, xPlayer, reward)
    local rewardType = reward.type
    local data = reward.data or {}

    if rewardType == 'item' then
        xPlayer.addInventoryItem(data.item, data.count or 1)
        return true, ('Dodano %sx %s do ekwipunku.'):format(data.count or 1, data.item)
    elseif rewardType == 'money' then
        if data.account and data.account ~= 'money' then
            xPlayer.addAccountMoney(data.account, data.amount or 0)
        else
            xPlayer.addMoney(data.amount or 0)
        end
        return true, ('Dodano %s$ na konto.'):format(data.amount or 0)
    elseif rewardType == 'group' then
        TriggerEvent('ghostmarket:grantGroup', source, data)
        return true, 'Uprawnienia zostały zaktualizowane.'
    elseif rewardType == 'vehicle' then
        TriggerEvent('ghostmarket:grantVehicle', source, data)
        return true, 'Pojazd został przekazany do garażu.'
    elseif rewardType == 'event' then
        TriggerEvent(data.event, source, data)
        return true, 'Włączono wydarzenie specjalne.'
    elseif rewardType == 'ticket' then
        TriggerEvent('ghostmarket:createTicket', source, data)
        return true, 'Zgłoszenie zostało utworzone.'
    elseif rewardType == 'crate' then
        local crateData = data
        if not crateData or not crateData.rolls then
            return false, 'Skrzynka jest niepoprawnie skonfigurowana.'
        end

        local totalWeight = 0
        for _, roll in ipairs(crateData.rolls) do
            totalWeight = totalWeight + (roll.weight or 0)
        end

        local chance = math.random() * totalWeight
        local cumulative = 0
        local selected

        for _, roll in ipairs(crateData.rolls) do
            cumulative = cumulative + (roll.weight or 0)
            if chance <= cumulative then
                selected = roll.id
                break
            end
        end

        local nestedItem = Config.ShopItems[selected]
        if not nestedItem then
            return false, 'Wygrana nagroda nie istnieje.'
        end

        local ok, message = grantReward(source, xPlayer, nestedItem.reward)
        if ok then
            TriggerClientEvent('ghostmarket:crateResult', source, {
                crate = reward,
                reward = {
                    id = selected,
                    label = nestedItem.label,
                    type = nestedItem.type
                }
            })
        end
        return ok, message
    elseif rewardType == 'bundle' then
        if type(data) ~= 'table' then
            return false, 'Pakiet jest niepoprawnie skonfigurowany.'
        end

        for _, entry in ipairs(data) do
            if entry and entry.type then
                local success = grantReward(source, xPlayer, entry)
                if not success then
                    debugPrint('Błąd podczas przyznawania elementu pakietu', entry.type)
                end
            end
        end
        return true, 'Pakiet został dostarczony.'
    else
        TriggerEvent('ghostmarket:handleCustomReward', source, reward)
        return true, 'Nagroda została przyznana.'
    end
end

local function canAfford(balance, price)
    return balance >= price
end

local function openMarket(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end

    local identifier = getPlayerIdentifier(xPlayer)
    ensureWallet(identifier)
    local balance = getBalance(identifier)
    local configPayload = sanitizeItems()
    local activities = fetchActivity()
    local eventState = getEventState()

    TriggerClientEvent('ghostmarket:open', source, {
        config = configPayload,
        balance = balance,
        activity = activities,
        event = eventState
    })
end

RegisterNetEvent('ghostmarket:requestOpen', function()
    local src = source
    local allowed, remaining = checkCooldown(reopenCooldown, src, Config.Cooldowns.reopen)
    if not allowed then
        Config.Notification.error(src, ('Odczekaj %.1fs przed ponownym otwarciem tabletu.'):format(remaining))
        return
    end

    openMarket(src)
end)

RegisterNetEvent('ghostmarket:requestPurchase', function(itemId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return
    end

    local item = Config.ShopItems[itemId]
    if not item then
        Config.Notification.error(src, 'Produkt nie istnieje lub został wycofany.')
        return
    end

    local allowed = checkCooldown(purchaseCooldown, src, Config.Cooldowns.purchase)
    if not allowed then
        Config.Notification.error(src, 'Zakup jest chłodzony, spróbuj za chwilę.')
        return
    end

    local identifier = getPlayerIdentifier(xPlayer)
    local balance = getBalance(identifier)

    if not canAfford(balance, item.price) then
        Config.Notification.error(src, 'Brak wystarczającej liczby monet.')
        return
    end

    local success, message = grantReward(src, xPlayer, item.reward)
    if not success then
        Config.Notification.error(src, message or 'Wystąpił błąd podczas przyznawania nagrody.')
        return
    end

    local newBalance = addBalance(identifier, -item.price)
    recordActivity(identifier, itemId, 1, item.price)
    Config.Notification.success(src, message or 'Zakup zakończony powodzeniem.')
    TriggerClientEvent('ghostmarket:updateBalance', src, newBalance)
end)

RegisterCommand(Config.Commands.market, function(source)
    if source == 0 then
        print('Komenda market dostępna tylko w grze.')
        return
    end
    local allowed, remaining = checkCooldown(reopenCooldown, source, Config.Cooldowns.reopen)
    if not allowed then
        Config.Notification.error(source, ('Odczekaj %.1fs przed ponownym otwarciem tabletu.'):format(remaining))
        return
    end
    openMarket(source)
end, false)

local function resolveIdentifier(arg)
    if not arg then return nil end

    if tonumber(arg) then
        local player = ESX.GetPlayerFromId(tonumber(arg))
        if player then
            return getPlayerIdentifier(player), player.getName()
        end
        return nil
    end

    local player = ESX.GetPlayerFromIdentifier(arg)
    if player then
        return getPlayerIdentifier(player), player.getName()
    end

    return arg
end

RegisterCommand(Config.Commands.admin, function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.Admin.requiredAce) then
        Config.Notification.error(source, 'Brak uprawnień.')
        return
    end

    local action = args[1]
    local targetArg = args[2]
    local value = tonumber(args[3])

    if not action or not targetArg then
        if source ~= 0 then
            Config.Notification.error(source, 'Użycie: /' .. Config.Commands.admin .. ' <add|remove|set|show> <id/licence> [wartość]')
        else
            print('Użycie: ' .. Config.Commands.admin .. ' <add|remove|set|show> <id/licence> [wartość]')
        end
        return
    end

    local identifier, playerName = resolveIdentifier(targetArg)
    if not identifier then
        if source ~= 0 then
            Config.Notification.error(source, 'Nie znaleziono gracza ani konta o podanym identyfikatorze.')
        else
            print('Nie znaleziono gracza ani konta o podanym identyfikatorze.')
        end
        return
    end

    ensureWallet(identifier)

    if action == 'show' then
        local balance = getBalance(identifier)
        local message = ('Saldo %s: %d %s'):format(playerName or identifier, balance, Config.Currency.short)
        if source == 0 then
            print(message)
        else
            Config.Notification.success(source, message)
        end
        return
    end

    if not value then
        Config.Notification.error(source, 'Podaj wartość.')
        return
    end

    if action == 'add' then
        local newBalance = addBalance(identifier, value)
        local message = ('Dodano %d %s. Nowe saldo: %d %s'):format(value, Config.Currency.short, newBalance, Config.Currency.short)
        if source == 0 then
            print(message)
        else
            Config.Notification.success(source, message)
            local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
            if targetPlayer then
                TriggerClientEvent('ghostmarket:updateBalance', targetPlayer.source, newBalance)
            end
        end
    elseif action == 'remove' then
        local newBalance = addBalance(identifier, -value)
        local message = ('Usunięto %d %s. Nowe saldo: %d %s'):format(value, Config.Currency.short, newBalance, Config.Currency.short)
        if source == 0 then
            print(message)
        else
            Config.Notification.success(source, message)
            local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
            if targetPlayer then
                TriggerClientEvent('ghostmarket:updateBalance', targetPlayer.source, newBalance)
            end
        end
    elseif action == 'set' then
        setBalance(identifier, math.max(0, value))
        local message = ('Ustawiono saldo na %d %s'):format(value, Config.Currency.short)
        if source == 0 then
            print(message)
        else
            Config.Notification.success(source, message)
            local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
            if targetPlayer then
                TriggerClientEvent('ghostmarket:updateBalance', targetPlayer.source, value)
            end
        end
    else
        Config.Notification.error(source, 'Nieznane polecenie: ' .. action)
    end
end, true)

RegisterCommand(Config.Commands.event, function(source, args)
    if not Config.EventTimer.enabled then
        Config.Notification.error(source, 'Licznik wydarzeń jest wyłączony w konfiguracji.')
        return
    end

    if source ~= 0 and not IsPlayerAceAllowed(source, Config.EventTimer.requiredAce or Config.Admin.requiredAce) then
        Config.Notification.error(source, 'Brak uprawnień.')
        return
    end

    local action = args[1]
    if action == 'show' then
        local state = getEventState()
        if state and state.expires then
            local message = ('Wydarzenie trwa do %s'):format(state.expires)
            if source == 0 then
                print(message)
            else
                Config.Notification.success(source, message)
            end
        else
            if source == 0 then
                print('Brak aktywnego wydarzenia.')
            else
                Config.Notification.error(source, 'Brak aktywnego wydarzenia.')
            end
        end
        return
    elseif action == 'clear' then
        setEventState(nil)
        if source == 0 then
            print('Wydarzenie wyzerowane.')
        else
            Config.Notification.success(source, 'Wydarzenie zostało wyzerowane.')
        end
        TriggerClientEvent('ghostmarket:updateEvent', -1, nil)
        return
    elseif action == 'set' then
        local durationArg = args[2]
        if not durationArg then
            Config.Notification.error(source, 'Podaj czas w formacie 2h30m / 90 / 01:30:00')
            return
        end

        local minutes
        if durationArg:find('h') or durationArg:find('m') then
            local hours = tonumber(durationArg:match('(\d+)h')) or 0
            local mins = tonumber(durationArg:match('(\d+)m')) or 0
            minutes = hours * 60 + mins
        elseif durationArg:find(':') then
            local h, m, s = durationArg:match('(%d+):(%d+):?(%d*)')
            minutes = (tonumber(h) or 0) * 60 + (tonumber(m) or 0)
            if s and s ~= '' then
                minutes = minutes + math.floor((tonumber(s) or 0) / 60)
            end
        else
            minutes = tonumber(durationArg)
        end

        if not minutes or minutes <= 0 then
            Config.Notification.error(source, 'Nieprawidłowy czas.')
            return
        end

        local expires = os.date('!%Y-%m-%dT%H:%M:%SZ', os.time(os.date('!*t')) + minutes * 60)
        setEventState({
            expires = expires,
            minutes = minutes
        })

        if source == 0 then
            print(('Ustawiono wydarzenie na %d minut.'):format(minutes))
        else
            Config.Notification.success(source, ('Ustawiono wydarzenie na %d minut.'):format(minutes))
        end

        TriggerClientEvent('ghostmarket:updateEvent', -1, {
            expires = expires,
            minutes = minutes
        })
    else
        Config.Notification.error(source, 'Użycie: /' .. Config.Commands.event .. ' <set|show|clear> [czas]')
    end
end, true)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ensureTables()
    debugPrint('Tabele zostały sprawdzone.')
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    local identifier = getPlayerIdentifier(xPlayer)
    ensureWallet(identifier)
    local balance = getBalance(identifier)
    TriggerClientEvent('ghostmarket:updateBalance', playerId, balance)
end)

RegisterNetEvent('ghostmarket:requestBalance', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local identifier = getPlayerIdentifier(xPlayer)
    ensureWallet(identifier)
    local balance = getBalance(identifier)
    TriggerClientEvent('ghostmarket:updateBalance', src, balance)
end)
