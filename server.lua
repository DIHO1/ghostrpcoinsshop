local Config = Config

local ESX
if Config.Framework == 'esx' then
    local success, object = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if success and object then
        ESX = object
    else
        print('[Ghost Market] Nie udało się pobrać obiektu ESX. Upewnij się, że es_extended jest załadowany.')
    end
else
    print('[Ghost Market] Aktualnie wspierany jest wyłącznie framework ESX.')
end

local purchaseCooldowns = {}

math.randomseed(os.time())
math.random()
math.random()
math.random()

local heroCountdownConfig = Config.Layout and Config.Layout.hero and Config.Layout.hero.countdown or nil
local HERO_EVENT_KEY = 'hero_event'
if type(heroCountdownConfig) == 'table' and heroCountdownConfig.eventKey and heroCountdownConfig.eventKey ~= '' then
    HERO_EVENT_KEY = heroCountdownConfig.eventKey
end

local heroCountdownEndAt

local function currentUnixMillis()
    return math.floor(os.time() * 1000)
end

local function formatDurationFromSeconds(seconds)
    if not seconds or seconds <= 0 then
        return '0s'
    end

    local remaining = seconds
    local days = math.floor(remaining / 86400)
    remaining = remaining % 86400
    local hours = math.floor(remaining / 3600)
    remaining = remaining % 3600
    local minutes = math.floor(remaining / 60)
    local secs = remaining % 60

    local parts = {}
    if days > 0 then table.insert(parts, ('%dd'):format(days)) end
    if hours > 0 then table.insert(parts, ('%dh'):format(hours)) end
    if minutes > 0 then table.insert(parts, ('%dm'):format(minutes)) end
    if secs > 0 and days == 0 then table.insert(parts, ('%ds'):format(secs)) end

    if #parts == 0 then
        return ('%ds'):format(secs)
    end

    return table.concat(parts, ' ')
end

local function parseDurationToSeconds(arguments)
    if not arguments or #arguments == 0 then
        return nil
    end

    local joined = table.concat(arguments, ' '):lower()
    if joined == '' then
        return nil
    end

    local total = 0
    local matched = false

    for value, unit in joined:gmatch('(%d+)%s*([dhms])') do
        local number = tonumber(value)
        if number then
            matched = true
            if unit == 'd' then
                total = total + (number * 86400)
            elseif unit == 'h' then
                total = total + (number * 3600)
            elseif unit == 'm' then
                total = total + (number * 60)
            elseif unit == 's' then
                total = total + number
            end
        end
    end

    if matched then
        return total > 0 and total or nil
    end

    if joined:find(':', 1, true) then
        local segments = {}
        for segment in joined:gmatch('[^:]+') do
            segments[#segments + 1] = segment
        end

        if #segments == 2 or #segments == 3 then
            local hours = tonumber(segments[1]) or 0
            local minutes = tonumber(segments[2]) or 0
            local seconds = tonumber(segments[3] or '0') or 0
            total = (hours * 3600) + (minutes * 60) + seconds
            if total > 0 then
                return total
            end
        end
    end

    local minutesValue = tonumber(joined)
    if minutesValue and minutesValue > 0 then
        return minutesValue * 60
    end

    return nil
end

local function buildEventStatePayload()
    local payload = {
        heroCountdown = {
            endAt = heroCountdownEndAt,
            serverTime = currentUnixMillis()
        }
    }

    return payload
end

local function sendEventState(target)
    local payload = buildEventStatePayload()

    if target then
        TriggerClientEvent('ghostmarket:updateEventState', target, payload)
    else
        TriggerClientEvent('ghostmarket:updateEventState', -1, payload)
    end
end

local function loadHeroCountdown()
    exports.oxmysql:fetch('SELECT end_at FROM ghost_shop_state WHERE event_key = ? LIMIT 1', {HERO_EVENT_KEY}, function(result)
        local row = result and result[1]
        if row and row.end_at then
            local parsed = tonumber(row.end_at)
            if parsed and parsed > 0 then
                heroCountdownEndAt = parsed
            else
                heroCountdownEndAt = nil
            end
        else
            heroCountdownEndAt = nil
        end

        sendEventState()

        if heroCountdownEndAt then
            local remainingMs = heroCountdownEndAt - currentUnixMillis()
            if remainingMs > 0 then
                local remainingSeconds = math.floor(remainingMs / 1000)
                print(('[Ghost Market] Wczytano licznik wydarzenia (pozostało %s).'):format(formatDurationFromSeconds(remainingSeconds)))
            else
                print('[Ghost Market] Wczytano licznik wydarzenia (czas już upłynął).')
            end
        else
            print('[Ghost Market] Brak aktywnego licznika wydarzenia przy starcie zasobu.')
        end
    end)
end

CreateThread(function()
    exports.oxmysql:execute([[CREATE TABLE IF NOT EXISTS `ghost_shop_wallet` (
        `identifier` VARCHAR(64) NOT NULL,
        `coins` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`identifier`)
    )]], {}, function(result)
        if result ~= nil then
            print('[Ghost Market] Tabela ghost_shop_wallet została zweryfikowana.')
        else
            print('[Ghost Market] Nie udało się utworzyć/zweryfikować tabeli ghost_shop_wallet. Sprawdź konfigurację bazy danych')
        end
    end)

    exports.oxmysql:execute([[CREATE TABLE IF NOT EXISTS `ghost_shop_state` (
        `event_key` VARCHAR(64) NOT NULL,
        `end_at` BIGINT NULL,
        PRIMARY KEY (`event_key`)
    )]], {}, function(result)
        if result ~= nil then
            print('[Ghost Market] Tabela ghost_shop_state została zweryfikowana.')
            loadHeroCountdown()
        else
            print('[Ghost Market] Nie udało się utworzyć/zweryfikować tabeli ghost_shop_state. Sprawdź konfigurację bazy danych.')
        end
    end)
end)

local printedAceHints = {}

local function printAceHint(context, ace)
    if not ace or ace == '' then
        return
    end

    if printedAceHints[ace] then
        return
    end

    printedAceHints[ace] = true

    print(('[Ghost Market] Uprawnienia ACE dla %s wymagają flagi "%s".'):format(context, ace))
    print(('[Ghost Market]   add_ace group.admin %s allow    # przykład nadania dostępu grupie'):format(ace))
    print('[Ghost Market]   add_principal identifier.steam:110000112345678 group.admin    # powiąż konkretnego gracza z grupą')
    print('[Ghost Market]   # możesz też użyć add_ace identifier.<typ>:<id> ' .. ace .. ' allow, aby nadać dostęp pojedynczej osobie')
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local adminConfig = Config.Admin or {}
    if adminConfig.command and adminConfig.command ~= '' then
        printAceHint(('/%s'):format(adminConfig.command), adminConfig.requiredAce)
    end

    local eventConfig = Config.EventTimer or {}
    if eventConfig.command and eventConfig.command ~= '' then
        local ace = eventConfig.requiredAce or adminConfig.requiredAce
        printAceHint(('/%s'):format(eventConfig.command), ace)
    end
end)

local function getPlayerIdentifier(xPlayer)
    return xPlayer and xPlayer.identifier
end

local function normalizeAffected(result)
    if type(result) == 'number' then
        return result
    end

    if type(result) == 'boolean' then
        return result and 1 or 0
    end

    if type(result) == 'table' then
        if result.affectedRows then
            return result.affectedRows
        end

        if result.changedRows then
            return result.changedRows
        end
    end

    return 0
end

local function ensureWallet(identifier, cb)
    exports.oxmysql:scalar('SELECT coins FROM ghost_shop_wallet WHERE identifier = ?', {identifier}, function(coins)
        if coins == nil then
            exports.oxmysql:insert('INSERT INTO ghost_shop_wallet (identifier, coins) VALUES (?, 0)', {identifier}, function(result)
                if result then
                    cb(0)
                else
                    print(('[Ghost Market] Nie udało się utworzyć portfela dla %s.'):format(identifier))
                    cb(nil)
                end
            end)
        else
            cb(coins)
        end
    end)
end

local function getCoins(identifier, cb)
    ensureWallet(identifier, function(balance)
        if balance == nil then
            print(('[Ghost Market] Nie udało się pobrać salda dla %s. Zwracam 0.'):format(identifier))
            cb(0)
            return
        end

        cb(balance)
    end)
end

local function addCoins(identifier, amount, cb)
    if amount <= 0 then
        if cb then cb(false) end
        return
    end

    ensureWallet(identifier, function(balance)
        if balance == nil then
            if cb then cb(false) end
            return
        end

        exports.oxmysql:update('UPDATE ghost_shop_wallet SET coins = coins + ? WHERE identifier = ?', {amount, identifier}, function(result)
            if normalizeAffected(result) > 0 then
                getCoins(identifier, function(balance)
                    if cb then cb(true, balance) end
                end)
            else
                if cb then cb(false) end
            end
        end)
    end)
end

local function removeCoins(identifier, amount, cb)
    if amount <= 0 then
        if cb then cb(false) end
        return
    end

    exports.oxmysql:update('UPDATE ghost_shop_wallet SET coins = coins - ? WHERE identifier = ? AND coins >= ?', {amount, identifier, amount}, function(result)
        if normalizeAffected(result) > 0 then
            getCoins(identifier, function(balance)
                if cb then cb(true, balance) end
            end)
        else
            if cb then cb(false) end
        end
    end)
end

local function giveDirectReward(xPlayer, rewardData)
    local rewardType = rewardData.type

    if rewardType == 'item' then
        if rewardData.item then
            local count = rewardData.count or 1
            xPlayer.addInventoryItem(rewardData.item, count)
            return true, {
                rewardType = 'item',
                item = rewardData.item,
                count = count,
                displayName = rewardData.displayName or rewardData.item
            }
        end
        return false, 'invalid_item'
    elseif rewardType == 'money' then
        local amount = rewardData.amount or 0
        if amount <= 0 then
            return false, 'invalid_amount'
        end

        local account = rewardData.account or 'money'
        if account == 'money' then
            xPlayer.addMoney(amount)
        else
            xPlayer.addAccountMoney(account, amount)
        end

        return true, {
            rewardType = 'money',
            amount = amount,
            account = account,
            displayName = rewardData.displayName or ('%s %s'):format(amount, account)
        }
    elseif rewardType == 'group' then
        if rewardData.group then
            local identifier = getPlayerIdentifier(xPlayer)
            if identifier then
                ExecuteCommand(('add_ace %s %s allow'):format(identifier, rewardData.group))
                return true, {
                    rewardType = 'group',
                    group = rewardData.group,
                    displayName = rewardData.displayName or rewardData.group
                }
            end
        end
        return false, 'invalid_group'
    elseif rewardType == 'vehicle' then
        print(('[Ghost Market] Gracz %s (%s) zakupił pojazd %s. Zintegruj nagrodę z zewnętrznym systemem garażu.')
            :format(xPlayer.getName(), getPlayerIdentifier(xPlayer) or 'unknown', rewardData.model or 'unknown'))
        return true, {
            rewardType = 'vehicle',
            model = rewardData.model,
            displayName = rewardData.displayName or rewardData.model
        }
    elseif rewardType == 'weapon' then
        if rewardData.weapon then
            local ammo = rewardData.ammo or 0
            xPlayer.addWeapon(rewardData.weapon, ammo)
            return true, {
                rewardType = 'weapon',
                weapon = rewardData.weapon,
                ammo = ammo,
                displayName = rewardData.displayName or rewardData.weapon
            }
        end
        return false, 'invalid_weapon'
    end

    return false, 'unknown_type'
end

local function selectCrateEntry(pool)
    if type(pool) ~= 'table' or #pool == 0 then
        return nil
    end

    local totalWeight = 0
    for _, entry in ipairs(pool) do
        totalWeight = totalWeight + (entry.weight or 1)
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local cumulative = 0

    for _, entry in ipairs(pool) do
        cumulative = cumulative + (entry.weight or 1)
        if roll <= cumulative then
            return entry
        end
    end

    return pool[#pool]
end

local function sanitizeCrateEntry(entry)
    if type(entry) ~= 'table' then
        return nil
    end

    return {
        id = entry.id,
        label = entry.label,
        icon = entry.icon,
        rarity = entry.rarity,
        prop = entry.prop
    }
end

local function sanitizeCratePool(pool)
    local sanitized = {}

    if type(pool) ~= 'table' then
        return sanitized
    end

    for index, entry in ipairs(pool) do
        local cleaned = sanitizeCrateEntry(entry)
        if cleaned then
            sanitized[index] = cleaned
        end
    end

    return sanitized
end

local function processReward(xPlayer, rewardData)
    if not rewardData or not rewardData.type then
        return false, 'invalid_reward'
    end

    if rewardData.type == 'crate' then
        local pool = rewardData.pool
        local selectedEntry = selectCrateEntry(pool)

        if not selectedEntry or not selectedEntry.reward then
            return false, 'invalid_crate'
        end

        local success, nestedInfo = processReward(xPlayer, selectedEntry.reward)
        if not success then
            return false, nestedInfo or 'crate_failed'
        end

        local sanitizedPool = sanitizeCratePool(pool)

        local crateInfo = {
            type = 'crate',
            crateLabel = rewardData.crateLabel or rewardData.label or 'Skrzynia',
            animation = rewardData.animation,
            highlight = rewardData.highlight,
            selection = {
                id = selectedEntry.id,
                label = selectedEntry.label,
                icon = selectedEntry.icon,
                rarity = selectedEntry.rarity,
                prop = selectedEntry.prop,
                rewardType = nestedInfo and nestedInfo.rewardType or (selectedEntry.reward and selectedEntry.reward.type),
                rewardDetails = nestedInfo,
                displayName = (selectedEntry.reward and selectedEntry.reward.displayName)
                    or (nestedInfo and nestedInfo.displayName)
            },
            poolPreview = sanitizedPool
        }

        return true, crateInfo
    end

    return giveDirectReward(xPlayer, rewardData)
end

local function distributeReward(playerSource, rewardData)
    if not rewardData or not rewardData.type then
        return false, 'invalid_reward'
    end

    if not ESX then
        return false, 'framework_unavailable'
    end

    local xPlayer = ESX.GetPlayerFromId(playerSource)
    if not xPlayer then
        return false, 'player_not_found'
    end

    return processReward(xPlayer, rewardData)
end

exports('GetCoins', function(identifier, cb)
    getCoins(identifier, cb)
end)

exports('AddCoins', function(identifier, amount, cb)
    addCoins(identifier, amount, cb)
end)

exports('RemoveCoins', function(identifier, amount, cb)
    removeCoins(identifier, amount, cb)
end)

exports('DistributeReward', function(playerSource, rewardData)
    return distributeReward(playerSource, rewardData)
end)

local function checkAdminPermission(src, overrideAce)
    if src == 0 then
        return true
    end

    local ace = overrideAce
    if not ace or ace == '' then
        ace = Config.Admin and Config.Admin.requiredAce or nil
    end

    if not ace or ace == '' then
        return true
    end

    return IsPlayerAceAllowed(src, ace)
end

local function resolveIdentifierFromArg(arg, invoker)
    if arg and arg ~= '' then
        if ESX and tonumber(arg) then
            local xPlayer = ESX.GetPlayerFromId(tonumber(arg))
            if xPlayer then
                local identifier = getPlayerIdentifier(xPlayer)
                if identifier then
                    return identifier
                end
            end
        end

        return arg
    end

    if invoker and invoker > 0 and ESX then
        local xPlayer = ESX.GetPlayerFromId(invoker)
        if xPlayer then
            return getPlayerIdentifier(xPlayer)
        end
    end

    return nil
end

local function adminFeedback(message)
    print(('[Ghost Market] %s'):format(message))
end

local adminCommand = Config.Admin and Config.Admin.command or nil
if adminCommand and adminCommand ~= '' then
    RegisterCommand(adminCommand, function(source, args)
        if not checkAdminPermission(source) then
            adminFeedback('Odmowa dostepu do polecenia administracyjnego.')
            return
        end

        local action = (args[1] or ''):lower()
        local identifier = resolveIdentifierFromArg(args[2], source)

        if action == '' or not identifier then
            adminFeedback(('Uzycie: /%s <add|remove|set|show> [identifier] <amount>'):format(adminCommand))
            return
        end

        if action == 'show' then
            getCoins(identifier, function(balance)
                adminFeedback(('Saldo %s: %d %s'):format(identifier, balance, Config.Currency.symbol))
            end)
            return
        end

        if action == 'add' then
            local amount = tonumber(args[3])
            if not amount or amount <= 0 then
                adminFeedback('Podaj dodatnia liczbe monet do przetworzenia.')
                return
            end

            addCoins(identifier, amount, function(success, balance)
                if success then
                    adminFeedback(('Dodano %d %s dla %s (nowe saldo: %d).'):format(amount, Config.Currency.symbol, identifier, balance or 0))
                else
                    adminFeedback('Nie udalo sie dodac monet.')
                end
            end)
        elseif action == 'remove' then
            local amount = tonumber(args[3])
            if not amount or amount <= 0 then
                adminFeedback('Podaj dodatnia liczbe monet do przetworzenia.')
                return
            end

            removeCoins(identifier, amount, function(success, balance)
                if success then
                    adminFeedback(('Usunieto %d %s z konta %s (nowe saldo: %d).'):format(amount, Config.Currency.symbol, identifier, balance or 0))
                else
                    adminFeedback('Nie udalo sie usunac monet. Sprawdz saldo.')
                end
            end)
        elseif action == 'set' then
            local amount = tonumber(args[3])
            if amount == nil or amount < 0 then
                adminFeedback('Podaj prawidlowa wartosc salda (0 lub wiecej).')
                return
            end

            ensureWallet(identifier, function(balance)
                if balance == nil then
                    adminFeedback('Nie udało się przygotować portfela gracza.')
                    return
                end

                exports.oxmysql:update('UPDATE ghost_shop_wallet SET coins = ? WHERE identifier = ?', {amount, identifier}, function(result)
                    if normalizeAffected(result) > 0 or amount == balance then
                        adminFeedback(('Ustawiono saldo %s na %d %s.'):format(identifier, amount, Config.Currency.symbol))
                    else
                        adminFeedback('Nie udało się ustawić salda. Sprawdź logi bazy danych.')
                    end
                end)
            end)
        else
            adminFeedback(('Nieznana akcja %s. Dostepne: add, remove, set, show.'):format(action))
        end
    end, true)
end

local eventTimerConfig = Config.EventTimer or {}
local eventCommand = eventTimerConfig.command
if eventCommand and eventCommand ~= '' then
    RegisterCommand(eventCommand, function(source, args)
        if not checkAdminPermission(source, eventTimerConfig.requiredAce) then
            adminFeedback('Odmowa dostepu do polecenia licznika wydarzenia.')
            return
        end

        local action = (args[1] or ''):lower()

        if action == 'set' then
            local durationArgs = {}
            for i = 2, #args do
                durationArgs[#durationArgs + 1] = args[i]
            end

            local seconds = parseDurationToSeconds(durationArgs)
            if not seconds then
                adminFeedback('Podaj czas w formacie np. 2h30m, 90 (minuty) lub 01:30:00.')
                return
            end

            local targetEnd = currentUnixMillis() + (seconds * 1000)

            exports.oxmysql:execute('INSERT INTO ghost_shop_state (event_key, end_at) VALUES (?, ?) ON DUPLICATE KEY UPDATE end_at = VALUES(end_at)', {HERO_EVENT_KEY, targetEnd}, function(result)
                if result ~= nil then
                    heroCountdownEndAt = targetEnd
                    adminFeedback(('Ustawiono licznik wydarzenia na %s (koniec: %s).'):format(formatDurationFromSeconds(seconds), os.date('%Y-%m-%d %H:%M:%S', targetEnd / 1000)))
                    sendEventState()
                else
                    adminFeedback('Nie udało się zapisać licznika wydarzenia w bazie danych.')
                end
            end)
        elseif action == 'clear' then
            exports.oxmysql:execute('DELETE FROM ghost_shop_state WHERE event_key = ?', {HERO_EVENT_KEY}, function(result)
                if result ~= nil then
                    heroCountdownEndAt = nil
                    adminFeedback('Wyczyszczono licznik wydarzenia.')
                    sendEventState()
                else
                    adminFeedback('Nie udało się wyczyścić licznika wydarzenia w bazie danych.')
                end
            end)
        elseif action == 'show' then
            if heroCountdownEndAt then
                local remainingMs = heroCountdownEndAt - currentUnixMillis()
                if remainingMs > 0 then
                    local secondsRemaining = math.floor(remainingMs / 1000)
                    adminFeedback(('Licznik wygasa za %s (o %s).'):format(formatDurationFromSeconds(secondsRemaining), os.date('%Y-%m-%d %H:%M:%S', heroCountdownEndAt / 1000)))
                else
                    adminFeedback(('Licznik wygasł o %s.'):format(os.date('%Y-%m-%d %H:%M:%S', heroCountdownEndAt / 1000)))
                end
            else
                adminFeedback('Brak aktywnego licznika wydarzenia.')
            end
        else
            adminFeedback(('Użycie: /%s <set|clear|show> [czas]'):format(eventCommand))
        end
    end, true)
end

RegisterNetEvent('ghostmarket:requestWallet', function()
    local src = source
    if not ESX then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = getPlayerIdentifier(xPlayer)
    if not identifier then return end

    getCoins(identifier, function(balance)
        TriggerClientEvent('ghostmarket:updateWallet', src, balance)
    end)
end)

RegisterNetEvent('ghostmarket:requestEventState', function()
    local src = source
    sendEventState(src)
end)

RegisterNetEvent('ghostmarket:purchaseItem', function(itemId)
    local src = source
    if not ESX then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = getPlayerIdentifier(xPlayer)
    if not identifier then return end

    local selectedItem
    for _, item in ipairs(Config.ShopItems) do
        if item.id == itemId then
            selectedItem = item
            break
        end
    end

    if not selectedItem then
        TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = 'item_not_found' })
        return
    end

    local now = GetGameTimer()
    if Config.AntiSpam.enabled then
        local lastPurchase = purchaseCooldowns[identifier] or 0
        if now - lastPurchase < Config.AntiSpam.cooldown then
            TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = 'cooldown' })
            return
        end
    end

    getCoins(identifier, function(balance)
        if balance < selectedItem.price then
            TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = 'insufficient_funds', balance = balance })
            return
        end

        removeCoins(identifier, selectedItem.price, function(success, newBalance)
            if not success then
                TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = 'transaction_error', balance = balance })
                return
            end

            local rewarded, rewardDetailsOrReason = distributeReward(src, selectedItem.rewardData)
            if not rewarded then
                addCoins(identifier, selectedItem.price, function()
                    getCoins(identifier, function(refundBalance)
                        TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = rewardDetailsOrReason or 'reward_failed', balance = refundBalance })
                    end)
                end)
                return
            end

            purchaseCooldowns[identifier] = now

            print(('[Ghost Market] Gracz %s (%s) kupił %s za %d %s.')
                :format(xPlayer.getName(), identifier, selectedItem.label, selectedItem.price, Config.Currency.symbol))

            if type(rewardDetailsOrReason) == 'table' and rewardDetailsOrReason.type == 'crate' then
                local selection = rewardDetailsOrReason.selection or {}
                print(('[Ghost Market]   › Skrzynia %s wylosowała %s (%s).')
                    :format(rewardDetailsOrReason.crateLabel or selectedItem.label,
                        selection.label or 'nieznana nagroda', selection.rarity or 'brak rzadkości'))
            end

            TriggerClientEvent('ghostmarket:purchaseResult', src, {
                success = true,
                balance = newBalance,
                item = {
                    id = selectedItem.id,
                    label = selectedItem.label
                },
                rewardContext = rewardDetailsOrReason
            })
        end)
    end)
end)
