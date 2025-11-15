local isOpen = false
local lastOpen = 0

local function setDisplay(state)
    SetNuiFocus(state, state)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(state)
    end

    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        FreezeEntityPosition(playerPed, state)
    end

    isOpen = state
end

local function send(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

local keyCommand = Config.Keybind.command or 'ghostmarket:tablet'

RegisterCommand(keyCommand, function()
    local now = GetGameTimer()
    if isOpen then
        setDisplay(false)
        send('close', {})
        return
    end

    if now - lastOpen < (Config.Cooldowns.reopen or 1000) * 1000 then
        TriggerServerEvent('ghostmarket:requestBalance')
        return
    end

    lastOpen = now
    TriggerServerEvent('ghostmarket:requestOpen')
end)

if Config.Keybind.enabled then
    RegisterKeyMapping(keyCommand, Config.Keybind.description, 'keyboard', Config.Keybind.key)
end

RegisterNUICallback('ghostmarket:close', function(_, cb)
    setDisplay(false)
    cb({})
end)

RegisterNUICallback('ghostmarket:purchase', function(data, cb)
    if not data or not data.itemId then
        cb({ok = false})
        return
    end
    TriggerServerEvent('ghostmarket:requestPurchase', data.itemId)
    cb({ok = true})
end)

RegisterNUICallback('ghostmarket:ready', function(_, cb)
    TriggerServerEvent('ghostmarket:requestBalance')
    cb({})
end)

RegisterNetEvent('ghostmarket:open', function(payload)
    setDisplay(true)
    send('open', payload)
end)

RegisterNetEvent('ghostmarket:updateBalance', function(balance)
    send('balance', {balance = balance})
end)

RegisterNetEvent('ghostmarket:updateEvent', function(state)
    send('event', state)
end)

RegisterNetEvent('ghostmarket:crateResult', function(data)
    send('crate', data)
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true) -- Look Left/Right
            DisableControlAction(0, 2, true) -- Look Up/Down
            DisableControlAction(0, 30, true) -- Move Left/Right
            DisableControlAction(0, 31, true) -- Move Up/Down
            DisableControlAction(0, 32, true) -- Move Up
            DisableControlAction(0, 33, true) -- Move Down
            DisableControlAction(0, 34, true) -- Move Left
            DisableControlAction(0, 35, true) -- Move Right
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 75, true) -- Exit vehicle
            DisableControlAction(0, 45, true) -- Reload / Exit
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
            DisableControlAction(0, 257, true) -- Input Attack 2
            DisablePlayerFiring(PlayerId(), true)

            EnableControlAction(0, 322, true) -- ESC
            EnableControlAction(0, 200, true) -- ESC

            if IsControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 200) then
                setDisplay(false)
                send('close', {})
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if isOpen then
        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            FreezeEntityPosition(playerPed, false)
        end
        SetNuiFocus(false, false)
        if SetNuiFocusKeepInput then
            SetNuiFocusKeepInput(false)
        end
        isOpen = false
    end
end)
