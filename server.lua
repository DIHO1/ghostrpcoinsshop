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

    local rewardType = rewardData.type

    if rewardType == 'item' then
        if rewardData.item then
            local count = rewardData.count or 1
            xPlayer.addInventoryItem(rewardData.item, count)
            return true
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

        return true
    elseif rewardType == 'group' then
        if rewardData.group then
            local identifier = getPlayerIdentifier(xPlayer)
            if identifier then
                ExecuteCommand(('add_ace %s %s allow'):format(identifier, rewardData.group))
                return true
            end
        end
        return false, 'invalid_group'
    elseif rewardType == 'vehicle' then
        print(('[Ghost Market] Gracz %s (%s) zakupił pojazd %s. Zintegruj nagrodę z zewnętrznym systemem garażu.')
            :format(xPlayer.getName(), getPlayerIdentifier(xPlayer) or 'unknown', rewardData.model or 'unknown'))
        return true
    else
        return false, 'unknown_type'
    end
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

local function checkAdminPermission(src)
    if src == 0 then
        return true
    end

    if not Config.Admin or not Config.Admin.requiredAce then
        return true
    end

    return IsPlayerAceAllowed(src, Config.Admin.requiredAce)
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

            local rewarded, rewardReason = distributeReward(src, selectedItem.rewardData)
            if not rewarded then
                addCoins(identifier, selectedItem.price, function()
                    getCoins(identifier, function(refundBalance)
                        TriggerClientEvent('ghostmarket:purchaseResult', src, { success = false, reason = rewardReason or 'reward_failed', balance = refundBalance })
                    end)
                end)
                return
            end

            purchaseCooldowns[identifier] = now

            print(('[Ghost Market] Gracz %s (%s) kupił %s za %d %s.')
                :format(xPlayer.getName(), identifier, selectedItem.label, selectedItem.price, Config.Currency.symbol))

            TriggerClientEvent('ghostmarket:purchaseResult', src, {
                success = true,
                balance = newBalance,
                item = {
                    id = selectedItem.id,
                    label = selectedItem.label
                }
            })
        end)
    end)
end)
