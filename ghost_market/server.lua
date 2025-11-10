--[[
    GHOST MARKET - SERVER-SIDE
    Author: Jules
]]

-- Framework Integration
local ESX = exports['es_extended']:getSharedObject()

-- Anti-Spam Tracker
local PlayerCooldowns = {}

-- Ensure oxmysql is started
if GetResourceState('oxmysql') ~= 'started' then
    error('oxmysql is not started. Ghost Market requires oxmysql to function.')
end

-- =============================================================================
-- DATABASE FUNCTIONS
-- =============================================================================

-- Get player's coin balance
local function getPlayerCoins(identifier, cb)
    exports.oxmysql:execute('SELECT coins FROM ghost_shop_wallet WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            cb(result[1].coins)
        else
            -- Create a wallet for the new player
            exports.oxmysql:execute('INSERT INTO ghost_shop_wallet (identifier, coins) VALUES (?, ?)', {identifier, 0})
            cb(0)
        end
    end)
end

-- Add coins to player's balance
local function addPlayerCoins(identifier, amount, cb)
    exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = coins + ? WHERE identifier = ?', {amount, identifier}, function(result)
        if cb then cb(result.affectedRows > 0) end
    end)
end

-- Remove coins from player's balance
local function removePlayerCoins(identifier, amount, cb)
    exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = coins - ? WHERE identifier = ?', {amount, identifier}, function(result)
        if cb then cb(result.affectedRows > 0) end
    end)
end

-- =============================================================================
-- REWARD DISTRIBUTION
-- =============================================================================

local function DistributeReward(source, rewardData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()

    if rewardData.type == 'item' then
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:AddItem(source, rewardData.name, rewardData.amount)
        else
            xPlayer.addInventoryItem(rewardData.name, rewardData.amount)
        end
        print(('[Ghost Market] Player %s (%s) received item: %s x%d'):format(xPlayer.getName(), identifier, rewardData.name, rewardData.amount))

    elseif rewardData.type == 'money' then
        if rewardData.account == 'money' then
            xPlayer.addMoney(rewardData.amount)
        else
            xPlayer.addAccountMoney(rewardData.account, rewardData.amount)
        end
        print(('[Ghost Market] Player %s (%s) received money: $%d to %s account'):format(xPlayer.getName(), identifier, rewardData.amount, rewardData.account))

    elseif rewardData.type == 'group' then
        local command = ('add_ace identifier.%s "group.%s" allow'):format(identifier, rewardData.name)
        ExecuteCommand(command)
        print(('[Ghost Market] Player %s (%s) was granted the group: %s'):format(xPlayer.getName(), identifier, rewardData.name))
        print(('[Ghost Market] Executed command: %s'):format(command))

    elseif rewardData.type == 'vehicle' then
        -- This requires integration with your garage script. For now, we log the action.
        print(('[Ghost Market] VEHICLE REWARD LOG: Player %s (%s) purchased vehicle model: %s. Plate: %s. Please integrate with your garage script to deliver it.'):format(xPlayer.getName(), identifier, rewardData.model, rewardData.plate or 'RANDOM'))
    end
end

-- =============================================================================
-- EVENTS & CALLBACKS
-- =============================================================================

-- Send initial data to the NUI when it's opened
RegisterNetEvent('ghost_market:getInitialData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    getPlayerCoins(identifier, function(coins)
        TriggerClientEvent('ghost_market:setInitialData', src, coins, Config.ShopItems, Config.Currency)
    end)
end)

-- Handle item purchase requests from the NUI
RegisterNetEvent('ghost_market:purchaseItem', function(itemIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Anti-Spam Check
    if Config.EnableAntiSpam then
        if PlayerCooldowns[src] and (GetGameTimer() - PlayerCooldowns[src] < Config.AntiSpamDelay) then
            return -- Silently ignore the request
        end
        PlayerCooldowns[src] = GetGameTimer()
    end

    local item = Config.ShopItems[itemIndex]
    if not item then
        print(('[Ghost Market] Player %s tried to purchase an invalid item index: %d'):format(xPlayer.getName(), itemIndex))
        return
    end

    local identifier = xPlayer.getIdentifier()
    getPlayerCoins(identifier, function(currentCoins)
        if currentCoins >= item.price then
            removePlayerCoins(identifier, item.price, function(success)
                if success then
                    DistributeReward(src, item.rewardData)
                    -- After purchase, fetch the new balance and update the NUI
                    getPlayerCoins(identifier, function(newCoins)
                        TriggerClientEvent('ghost_market:updateBalance', src, newCoins)
                    end)
                end
            end)
        else
            -- This case should ideally be prevented by the client-side, but as a fallback:
            print(('[Ghost Market] Player %s (%s) failed to purchase "%s" - insufficient funds.'):format(xPlayer.getName(), identifier, item.label))
        end
    end)
end)

-- =============================================================================
-- ADMIN COMMANDS
-- =============================================================================

RegisterCommand('addcoins', function(source, args, rawCommand)
    if source == 0 then -- Console command
        local targetIdentifier = args[1]
        local amount = tonumber(args[2])
        if not targetIdentifier or not amount or amount <= 0 then
            print('[Ghost Market] Usage: addcoins <identifier> <amount>')
            return
        end
        addPlayerCoins(targetIdentifier, amount, function(success)
            if success then
                print(('[Ghost Market] Added %d %s to %s.'):format(amount, Config.Currency.name, targetIdentifier))
            else
                print(('[Ghost Market] Could not find player with identifier: %s'):format(targetIdentifier))
            end
        end)
    else -- In-game command
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() == 'admin' then
            local targetPlayerId = tonumber(args[1])
            local amount = tonumber(args[2])
            local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)

            if not targetPlayer or not amount or amount <= 0 then
                print(('[Ghost Market] Admin %s used /addcoins with invalid arguments.'):format(xPlayer.getName()))
                return
            end

            addPlayerCoins(targetPlayer.getIdentifier(), amount, function(success)
                if success then
                    print(('[Ghost Market] Admin %s gave %d %s to player %s.'):format(xPlayer.getName(), amount, Config.Currency.name, targetPlayer.getName()))
                end
            end)
        else
            print(('[Ghost Market] Non-admin %s tried to use /addcoins.'):format(xPlayer.getName()))
        end
    end
end, true)

RegisterCommand('setcoins', function(source, args, rawCommand)
    if source == 0 then -- Console command
        local targetIdentifier = args[1]
        local amount = tonumber(args[2])
        if not targetIdentifier or not amount or amount < 0 then
            print('[Ghost Market] Usage: setcoins <identifier> <amount>')
            return
        end
        exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = ? WHERE identifier = ?', {amount, targetIdentifier}, function(result)
            if result.affectedRows > 0 then
                print(('[Ghost Market] Set %s balance to %d %s.'):format(targetIdentifier, amount, Config.Currency.name))
            else
                 -- If no rows affected, try inserting a new record
                exports.oxmysql:execute('INSERT INTO ghost_shop_wallet (identifier, coins) VALUES (?, ?)', {targetIdentifier, amount}, function()
                    print(('[Ghost Market] Created wallet for %s and set balance to %d %s.'):format(targetIdentifier, amount, Config.Currency.name))
                end)
            end
        end)
    else -- In-game command
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() == 'admin' then
            local targetPlayerId = tonumber(args[1])
            local amount = tonumber(args[2])
            local targetPlayer = ESX.GetPlayerFromId(targetPlayerId)

            if not targetPlayer or not amount or amount < 0 then
                print(('[Ghost Market] Admin %s used /setcoins with invalid arguments.'):format(xPlayer.getName()))
                return
            end

            exports.oxmysql:execute('UPDATE ghost_shop_wallet SET coins = ? WHERE identifier = ?', {amount, targetPlayer.getIdentifier()}, function(result)
                if result.affectedRows > 0 then
                     print(('[Ghost Market] Admin %s set %s\'s balance to %d %s.'):format(xPlayer.getName(), targetPlayer.getName(), amount, Config.Currency.name))
                else
                    exports.oxmysql:execute('INSERT INTO ghost_shop_wallet (identifier, coins) VALUES (?, ?)', {targetPlayer.getIdentifier(), amount}, function()
                        print(('[Ghost Market] Admin %s created wallet for %s and set balance to %d %s.'):format(xPlayer.getName(), targetPlayer.getName(), amount, Config.Currency.name))
                    end)
                end
            end)
        else
            print(('[Ghost Market] Non-admin %s tried to use /setcoins.'):format(xPlayer.getName()))
        end
    end
end, true)

print('^2[Ghost Market] Server script loaded successfully.^7')
