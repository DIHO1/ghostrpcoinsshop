local Config = Config

local isOpen = false
local hasFocus = false
local currentBalance = 0
local currentEventState = {}
local cratePreview = {
    entity = nil,
    cam = nil,
    model = nil,
    type = nil
}

local function cleanupCratePreview()
    if cratePreview.cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cratePreview.cam, false)
        cratePreview.cam = nil
    end

    if cratePreview.entity and DoesEntityExist(cratePreview.entity) then
        DeleteEntity(cratePreview.entity)
    end

    if cratePreview.model then
        SetModelAsNoLongerNeeded(cratePreview.model)
    end

    cratePreview.entity = nil
    cratePreview.model = nil
    cratePreview.type = nil
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

local function spawnCratePreview(context)
    cleanupCratePreview()

    if type(context) ~= 'table' or context.type ~= 'crate' then
        return
    end

    local selection = context.selection
    if type(selection) ~= 'table' then
        return
    end

    local rewardType = selection.rewardType
    local details = selection.rewardDetails or {}
    local prop = selection.prop or {}

    if not rewardType and details.rewardType then
        rewardType = details.rewardType
    end

    local modelName = prop.worldModel or prop.model or details.worldModel

    if rewardType == 'vehicle' then
        modelName = modelName or details.model or prop.model
    elseif rewardType == 'weapon' then
        modelName = modelName or prop.weaponModel
        if not modelName and details.weapon then
            modelName = determineWeaponModel(details.weapon)
        end
    elseif rewardType == 'ammo' then
        modelName = modelName or prop.weaponModel
        if not modelName and details.weapon then
            modelName = determineWeaponModel(details.weapon)
        end
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
            SetVehicleOnGroundProperly(entity)
            SetVehicleEngineOn(entity, false, true, false)
            SetVehicleDoorsLocked(entity, 4)
            SetEntityCollision(entity, false, false)
        end
    else
        entity = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
        if entity ~= 0 then
            SetEntityCollision(entity, false, false)
        end
    end

    if not entity or entity == 0 then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)

    cratePreview.entity = entity
    cratePreview.model = modelHash
    cratePreview.type = rewardType

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camCoords = vector3(
        spawnCoords.x - forward.x * camDistance,
        spawnCoords.y - forward.y * camDistance,
        spawnCoords.z + camHeight
    )

    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cam, spawnCoords.x, spawnCoords.y, spawnCoords.z + (rewardType == 'vehicle' and 0.5 or 0.2))
    RenderScriptCams(true, true, 500, true, true)

    cratePreview.cam = cam

    CreateThread(function()
        if not cratePreview or not cratePreview.entity or not DoesEntityExist(entity) then return end

        local startTime = GetGameTimer()
        local duration = 10000 -- 10 seconds
        local endTime = startTime + duration

        local initialHeading = GetEntityHeading(entity)
        local totalRotation = 720.0 -- Two full rotations

        local pointAtOffset = rewardType == 'vehicle' and 0.5 or 0.2

        local pedForward = GetEntityForwardVector(PlayerPedId())
        local rightVector = vector3(pedForward.y, -pedForward.x, 0)

        while GetGameTimer() < endTime do
            if not cratePreview or cratePreview.entity ~= entity or not DoesEntityExist(entity) then
                break
            end

            local elapsed = GetGameTimer() - startTime
            local progress = elapsed / duration -- 0.0 to 1.0
            local easedProgress = -0.5 * (math.cos(math.pi * progress) - 1)

            -- Rotate entity
            local currentRotation = initialHeading + totalRotation * easedProgress
            if IsEntityAVehicle(entity) then
                SetEntityHeading(entity, currentRotation)
            else
                SetEntityRotation(entity, 0.0, 0.0, currentRotation, 2, true)
            end

            -- Animate camera
            local orbitAngle = math.rad(180 * easedProgress) -- Orbit 180 degrees
            local currentDistance = camDistance + 1.5 - (1.5 * easedProgress) -- Zoom in
            local currentHeight = camHeight - 0.5 + (0.5 * easedProgress) -- Rise up

            local camOffsetX = -pedForward.x * math.cos(orbitAngle) + rightVector.x * math.sin(orbitAngle)
            local camOffsetY = -pedForward.y * math.cos(orbitAngle) + rightVector.y * math.sin(orbitAngle)

            local camX = spawnCoords.x + camOffsetX * currentDistance
            local camY = spawnCoords.y + camOffsetY * currentDistance

            SetCamCoord(cam, camX, camY, spawnCoords.z + currentHeight)
            PointCamAtCoord(cam, spawnCoords.x, spawnCoords.y, spawnCoords.z + pointAtOffset)

            Wait(0)
        end

        if cratePreview and cratePreview.entity == entity and DoesEntityExist(entity) then
            -- Set final state
            local finalRotation = initialHeading + totalRotation
            if IsEntityAVehicle(entity) then
                SetEntityHeading(entity, finalRotation)
            else
                SetEntityRotation(entity, 0.0, 0.0, finalRotation, 2, true)
            end

            local finalOrbitAngle = math.rad(180)
            local finalCamOffsetX = -pedForward.x * math.cos(finalOrbitAngle) + rightVector.x * math.sin(finalOrbitAngle)
            local finalCamOffsetY = -pedForward.y * math.cos(finalOrbitAngle) + rightVector.y * math.sin(finalOrbitAngle)

            local finalCamX = spawnCoords.x + finalCamOffsetX * camDistance
            local finalCamY = spawnCoords.y + finalCamOffsetY * camDistance

            SetCamCoord(cam, finalCamX, finalCamY, spawnCoords.z + camHeight)
            PointCamAtCoord(cam, spawnCoords.x, spawnCoords.y, spawnCoords.z + pointAtOffset)
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
    cleanupCratePreview()
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
    cleanupCratePreview()
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
        spawnCratePreview(result.rewardContext)
    else
        cleanupCratePreview()
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
    cleanupCratePreview()
end)

RegisterKeyMapping(Config.OpenCommand, 'Otwórz Ghost Market', 'keyboard', 'F7')

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('ghostmarket:requestEventState')
end)
