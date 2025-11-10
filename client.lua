local Config = Config

local isOpen = false
local hasFocus = false
local currentBalance = 0

local function toggleFocus(state)
    hasFocus = state
    SetNuiFocus(state, state)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
end

local function openMarket()
    if isOpen then return end

    isOpen = true
    toggleFocus(true)

    SendNUIMessage({
        action = 'open',
        items = Config.ShopItems,
        currency = Config.Currency,
        layout = Config.Layout
    })

    TriggerServerEvent('ghostmarket:requestWallet')
end

local function closeMarket()
    if not isOpen then return end

    isOpen = false
    toggleFocus(false)

    SendNUIMessage({
        action = 'close'
    })
end

RegisterCommand(Config.OpenCommand, function()
    if isOpen then
        closeMarket()
    else
        openMarket()
    end
end, false)

RegisterNUICallback('closeMarket', function(_, cb)
    closeMarket()
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    if not data or not data.id then
        cb('error')
        return
    end

    TriggerServerEvent('ghostmarket:purchaseItem', data.id)
    cb('ok')
end)

RegisterNetEvent('ghostmarket:updateWallet', function(balance)
    currentBalance = balance or 0
    SendNUIMessage({
        action = 'updateWallet',
        balance = currentBalance,
        currency = Config.Currency
    })
end)

RegisterNetEvent('ghostmarket:purchaseResult', function(result)
    if result and result.success then
        currentBalance = result.balance or currentBalance
    elseif result and result.balance then
        currentBalance = result.balance
    end

    SendNUIMessage({
        action = 'purchaseResult',
        result = result,
        currency = Config.Currency
    })
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

RegisterNUICallback('ready', function(_, cb)
    SendNUIMessage({
        action = 'updateWallet',
        balance = currentBalance,
        currency = Config.Currency
    })
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if hasFocus or isOpen then
        toggleFocus(false)
    end
end)

RegisterKeyMapping(Config.OpenCommand, 'Otwórz Ghost Market', 'keyboard', 'F7')
