--[[
    GHOST MARKET - CLIENT-SIDE
    Author: Jules
]]

local isNuiOpen = false

-- =============================================================================
-- NUI MANAGEMENT
-- =============================================================================

function setNuiState(state)
    isNuiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = 'setVisible',
        status = state
    })
end

-- Command to open/close the market
RegisterCommand(Config.OpenCommand, function()
    if isNuiOpen then
        setNuiState(false)
    else
        -- Request initial data from the server before opening
        TriggerServerEvent('ghost_market:getInitialData')
    end
end, false)

-- Key mapping for closing with ESC
CreateThread(function()
    while true do
        if isNuiOpen and IsControlJustReleased(0, 322) then -- 322 is the key code for ESC
            setNuiState(false)
        end
        -- Performance optimization: wait longer if the NUI is closed
        Citizen.Wait(isNuiOpen and 1 or 1000)
    end
end)

-- =============================================================================
-- NUI CALLBACKS & EVENTS
-- =============================================================================

-- Callback for when the NUI is closed by the user (e.g., clicking a close button)
RegisterNUICallback('closeNui', function(_, cb)
    setNuiState(false)
    if cb then cb('ok') end
end)

-- Callback for purchasing an item
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemIndex = data.itemIndex
    if itemIndex then
        TriggerServerEvent('ghost_market:purchaseItem', itemIndex)
    end
    if cb then cb('ok') end
end)

-- Event to receive initial data from the server and open the NUI
RegisterNetEvent('ghost_market:setInitialData', function(balance, items, currency)
    local resourceName = GetCurrentResourceName()
    SendNUIMessage({
        action = 'initialize',
        balance = balance,
        items = items,
        currency = currency,
        resourceName = resourceName
    })
    setNuiState(true)
end)

-- Event to update the balance in the NUI after a purchase
RegisterNetEvent('ghost_market:updateBalance', function(newBalance)
    if isNuiOpen then
        SendNUIMessage({
            action = 'updateBalance',
            balance = newBalance
        })
    end
end)

print('^2[Ghost Market] Client script loaded successfully.^7')
