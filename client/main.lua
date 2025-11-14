local isOpen = false
local lastOpen = 0

local function setDisplay(state)
    SetNuiFocus(state, state)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(state)
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
        Wait(0)
        if isOpen and IsControlJustPressed(0, 200) then -- ESC
            setDisplay(false)
            send('close', {})
        end
    end
end)
