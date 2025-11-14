local Config = Config

local isOpen = false
local hasFocus = false
local currentBalance = 0
local currentEventState = {}
local worldPreview = {
    entity = nil,
    cam = nil,
    model = nil,
    type = nil,
    priority = 0
}

local function cleanupWorldPreview(force)
    if not force and worldPreview.type == 'crate' then
        return
    end

    if worldPreview.cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(worldPreview.cam, false)
        worldPreview.cam = nil
    end

    if worldPreview.entity and DoesEntityExist(worldPreview.entity) then
        DeleteEntity(worldPreview.entity)
    end

    if worldPreview.model then
        SetModelAsNoLongerNeeded(worldPreview.model)
    end

    ClearFocus()

    worldPreview.entity = nil
    worldPreview.model = nil
    worldPreview.type = nil
    worldPreview.priority = 0
end

local function loadModel(modelName)
    if not modelName or modelName == '' then
        return nil
    end

    local modelHash = modelName
    if type(modelHash) == 'string' then
        modelHash = GetHashKey(modelHash)
    end

    if not modelHash or modelHash == 0 or not IsModelInCdimage(modelHash) then
        return nil
    end

    RequestModel(modelHash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > timeout then
            return nil
        end
        Wait(0)
    end

    return modelHash
end

local function determineWeaponModel(weaponName)
    if not weaponName or weaponName == '' then
        return nil
    end

    local weaponHash = GetHashKey(weaponName)
    if weaponHash == 0 then
        return nil
    end

    local weaponModel = GetWeapontypeModel(weaponHash)
    if weaponModel and weaponModel ~= 0 then
        return weaponModel
    end

    return nil
end

local function resolvePreviewModel(rewardType, prop, details)
    local modelName = nil

    if prop then
        modelName = prop.worldModel or prop.model or prop.vehicleModel or prop.weaponModel
    end

    if not modelName and details then
        modelName = details.worldModel or details.model or details.vehicleModel or details.weaponModel
    end

    if rewardType == 'vehicle' then
        modelName = modelName or (details and details.model) or (prop and prop.model)
    elseif rewardType == 'weapon' or rewardType == 'ammo' then
        modelName = modelName or (prop and prop.weaponModel)
        if not modelName and details and details.weapon then
            modelName = determineWeaponModel(details.weapon)
        end
    end

    return modelName
end

local function spawnWorldPreview(context, priority)
    if type(context) ~= 'table' then
        return
    end

    priority = priority or 10

    if worldPreview.priority > 0 and priority < worldPreview.priority then
        return
    end

    cleanupWorldPreview(true)

    local previewType = context.previewType or context.type or 'item'

    local rewardType = context.rewardType
    local details = context.rewardDetails or context.rewardData or {}
    local prop = context.prop or {}
    local selection = context.selection

    if not rewardType and selection then
        rewardType = selection.rewardType or (selection.rewardDetails and selection.rewardDetails.rewardType)
        if not details or next(details) == nil then
            details = selection.rewardDetails or {}
        end
        if (not prop or next(prop) == nil) and selection.prop then
            prop = selection.prop
        end
    end

    if not rewardType and details and details.type then
        rewardType = details.type
    end

    if previewType == 'crate' and not rewardType then
        rewardType = 'crate'
    end

    local modelName = resolvePreviewModel(rewardType, prop, details)

    if not modelName and rewardType == 'crate' and details and details.model then
        modelName = details.model
    end

    if not modelName then
        return
    end

    local modelHash = loadModel(modelName)
    if not modelHash then
        return
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)

    local offsetDistance = 2.5
    local heightOffset = 0.35
    local camDistance = 3.5
    local camHeight = 1.25

    local isVehicle = IsModelAVehicle(modelHash)

    if rewardType == 'vehicle' or isVehicle then
        offsetDistance = 4.8
        heightOffset = 0.0
        camDistance = 6.5
        camHeight = 1.85
        rewardType = 'vehicle'
    elseif rewardType == 'weapon' or rewardType == 'ammo' then
        offsetDistance = 2.0
        heightOffset = 0.55
        camDistance = 3.0
        camHeight = 1.4
    end

    local spawnCoords = vector3(
        pedCoords.x + forward.x * offsetDistance,
        pedCoords.y + forward.y * offsetDistance,
        pedCoords.z + heightOffset
    )

    local heading = GetEntityHeading(ped)
    local entity

    if isVehicle then
        entity = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, false, false)
        if entity ~= 0 then
            SetEntityAsMissionEntity(entity, true, true)
            SetVehicleOnGroundProperly(entity)
            SetVehicleEngineOn(entity, false, true, false)
            SetVehicleDoorsLocked(entity, 4)
            SetEntityCollision(entity, false, false)
        end
    else
        entity = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
        if entity ~= 0 then
            SetEntityAsMissionEntity(entity, true, true)
            SetEntityCollision(entity, false, false)
        end
    end

    if not entity or entity == 0 then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)

    worldPreview.entity = entity
    worldPreview.model = modelHash
    worldPreview.type = previewType or rewardType
    worldPreview.priority = priority

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    SetCamFov(cam, rewardType == 'vehicle' and 55.0 or 60.0)
    local camCoords = vector3(
        spawnCoords.x - forward.x * camDistance,
        spawnCoords.y - forward.y * camDistance,
        spawnCoords.z + camHeight
    )

    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, spawnCoords.x, spawnCoords.y, spawnCoords.z + (rewardType == 'vehicle' and 0.5 or 0.2))
    SetFocusPosAndVel(spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, 0.0, 0.0)
    RenderScriptCams(true, true, 500, true, true)

    worldPreview.cam = cam

    CreateThread(function()
        local angle = heading
        while worldPreview.entity == entity do
            angle = angle + 0.25
            if angle >= 360.0 then
                angle = angle - 360.0
            end

            if IsEntityAVehicle(entity) then
                SetEntityHeading(entity, angle)
            else
                SetEntityRotation(entity, 0.0, 0.0, angle, 2, true)
            end

            Wait(0)
        end
    end)

    SetModelAsNoLongerNeeded(modelHash)
end

local function hasHeroCountdown()
    if type(currentEventState) ~= 'table' then
        return false
    end

    local countdown = currentEventState.heroCountdown
    if type(countdown) ~= 'table' then
        return false
    end

    return true
end

local function sendCountdownTick()
    if not isOpen then
        return
    end

    if not hasHeroCountdown() then
        return
    end

    SendNUIMessage({
        action = 'tickCountdown'
    })
end

local function toggleFocus(state)
    hasFocus = state
    SetNuiFocus(state, state)
    if SetNuiFocusKeepInput then
        SetNuiFocusKeepInput(false)
    end
end

local function sendEventStateToNui()
    if not currentEventState then
        return
    end

    if not isOpen then
        return
    end

    SendNUIMessage({
        action = 'updateEventState',
        state = currentEventState
    })
end

local function openMarket()
    if isOpen then return end

    isOpen = true
    toggleFocus(true)

    SendNUIMessage({
        action = 'open',
        items = Config.ShopItems,
        currency = Config.Currency,
        layout = Config.Layout,
        eventState = currentEventState
    })

    TriggerServerEvent('ghostmarket:requestWallet')
    TriggerServerEvent('ghostmarket:requestEventState')
    sendEventStateToNui()
    sendCountdownTick()
end

local function closeMarket()
    if not isOpen then return end

    isOpen = false
    cleanupWorldPreview(true)
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

RegisterNUICallback('crateClosed', function(_, cb)
    cleanupWorldPreview(true)
    cb('ok')
end)

RegisterNUICallback('previewItem', function(data, cb)
    cb('ok')

    if not isOpen then
        cleanupWorldPreview(true)
        return
    end

    if type(data) ~= 'table' then
        return
    end

    local enabled = data.enabled

    if type(enabled) == 'string' then
        enabled = enabled == '1' or enabled == 'true'
    end

    if not enabled then
        if worldPreview.type ~= 'crate' then
            cleanupWorldPreview(true)
        end
        return
    end

    local context = data.context
    if type(context) ~= 'table' then
        return
    end

    local priority = tonumber(data.priority) or 10

    if (context.previewType or context.type) == 'crate' then
        priority = math.max(priority, 50)
    end

    spawnWorldPreview(context, priority)
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

RegisterNetEvent('ghostmarket:updateEventState', function(state)
    if type(state) ~= 'table' then
        return
    end

    for key, value in pairs(state) do
        currentEventState[key] = value
    end

    sendEventStateToNui()
    sendCountdownTick()
end)

RegisterNetEvent('ghostmarket:purchaseResult', function(result)
    if result and result.success then
        currentBalance = result.balance or currentBalance
    elseif result and result.balance then
        currentBalance = result.balance
    end

    if result and result.rewardContext and result.rewardContext.type == 'crate' then
        spawnWorldPreview(result.rewardContext, 100)
    else
        cleanupWorldPreview(false)
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

CreateThread(function()
    while true do
        if isOpen and hasHeroCountdown() then
            sendCountdownTick()
            Wait(1000)
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
    cleanupWorldPreview(true)
end)

RegisterKeyMapping(Config.OpenCommand, 'Otwórz Ghost Market', 'keyboard', 'F7')

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('ghostmarket:requestEventState')
end)
