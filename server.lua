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

local function getPlayerIdentifier(xPlayer)
    return xPlayer and xPlayer.identifier
end

local function ensureWallet(identifier, cb)
    exports.oxmysql:scalar('SELECT coins FROM ghost_shop_wallet WHERE identifier = ?', {identifier}, function(coins)
        if coins == nil then
            exports.oxmysql:execute('INSERT INTO ghost_shop_wallet (identifier, coins) VALUES (?, 0)', {identifier}, function()
                cb(0)
            end)
        else
            cb(coins)
        end
    end)
end

local function getCoins(identifier, cb)
    ensureWallet(identifier, function(balance)
        cb(balance)
    end)
end

local function addCoins(identifier, amount, cb)
    if amount <= 0 then
        if cb then cb(false) end
        return
    end

    ensureWallet(identifier, function()
        exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = coins + ? WHERE identifier = ?', {amount, identifier}, function(affected)
            if affected and affected > 0 then
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

    exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = coins - ? WHERE identifier = ? AND coins >= ?', {amount, identifier, amount}, function(affected)
        if affected and affected > 0 then
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
