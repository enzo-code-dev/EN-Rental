--[[
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
]]

local RentedVehicles = {}
local Blips = {}
local Peds = {}
local MenuOpen = false
local CurrentLocation = nil
local PromptVisible = false

local Rental = Config.Rental or {}
local Interaction = Config.Interaction or {}
local Text = Config.Text or {}

local function DebugPrint(...)
    if Config.Debug then
        print('[ENZO CODE][Rental][Client]', ...)
    end
end

local function Notify(notifyType, message, title)
    SendNUIMessage({
        action = 'notify',
        type = notifyType or 'info',
        title = title,
        message = message
    })
end

RegisterNetEvent('lar_rental:notify', function(data)
    if type(data) ~= 'table' then return end
    Notify(data.type, data.message, data.title)
end)

local function SetPrompt(visible)
    if PromptVisible == visible then return end
    PromptVisible = visible

    SendNUIMessage({
        action = 'prompt',
        visible = visible,
        text = Text.interact or 'Press E to open ENZO Rental',
        key = Interaction.KeyLabel or 'E'
    })
end

local function CloseRentMenu()
    if not MenuOpen then return end

    MenuOpen = false
    CurrentLocation = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })
end

local function LoadModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000

    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() > timeout then
            return nil
        end
    end

    return hash
end

local function GetVehicleData(model)
    for _, vehicle in ipairs(Config.Vehicles or {}) do
        if tostring(vehicle.model) == tostring(model) then
            return vehicle
        end
    end

    return nil
end

local function IsSpawnClear(locationIndex)
    local location = Config.Locations and Config.Locations[locationIndex]
    if not location or not location.spawn then return false end

    return not IsAnyVehicleNearPoint(
        location.spawn.x,
        location.spawn.y,
        location.spawn.z,
        tonumber(Rental.SpawnClearRadius) or 3.0
    )
end

local function ResolveContextValue(name, context)
    if name == 'plate' then return context.plate end
    if name == 'netId' then return context.netId end
    if name == 'entity' then return context.entity end
    if name == 'model' then return context.model end
    if name == 'fuel' then return context.fuel end
    if name == 'source' then return GetPlayerServerId(PlayerId()) end
    return name
end

local function BuildActionArgs(argNames, context)
    local args = {}
    for _, argName in ipairs(argNames or {}) do
        args[#args + 1] = ResolveContextValue(argName, context)
    end
    return args
end

local function ExecuteBridgeAction(action, context)
    if type(action) ~= 'table' or not action.Type or not action.Name then
        return false
    end

    local args = BuildActionArgs(action.Args, context)
    local actionType = string.lower(tostring(action.Type))

    if actionType == 'client_event' then
        TriggerEvent(action.Name, table.unpack(args))
        return true
    end

    if actionType == 'server_event' then
        TriggerServerEvent(action.Name, table.unpack(args))
        return true
    end

    if actionType == 'export' then
        local resource = action.Resource
        if not resource or resource == '' or GetResourceState(resource) ~= 'started' then
            DebugPrint(('Skipped export %s because resource is not started.'):format(tostring(action.Name)))
            return false
        end

        local ok, err = pcall(function()
            exports[resource][action.Name](table.unpack(args))
        end)

        if not ok then
            DebugPrint(('Export bridge failed: %s'):format(tostring(err)))
        end
        return ok
    end

    return false
end

local function ExecuteBridgeActions(actions, context)
    if type(actions) ~= 'table' then return end

    -- Accept either one action table or an array of action tables.
    if actions.Type then
        ExecuteBridgeAction(actions, context)
        return
    end

    for _, action in ipairs(actions) do
        ExecuteBridgeAction(action, context)
    end
end

local function ResolveKeyPreset()
    local settings = Config.VehicleKeys or {}
    local system = string.lower(tostring(settings.System or 'none'))

    if system == 'none' then
        return nil, 'none'
    end

    if system == 'custom' then
        return settings.Custom or {}, 'custom'
    end

    if system == 'auto' then
        for _, presetName in ipairs(settings.AutoOrder or {}) do
            local preset = settings.Presets and settings.Presets[presetName]
            if preset and preset.Resource and GetResourceState(preset.Resource) == 'started' then
                return preset, presetName
            end
        end
        return nil, 'none'
    end

    local preset = settings.Presets and settings.Presets[system]
    return preset, system
end

local function HandleVehicleKeys(mode, context)
    local settings = Config.VehicleKeys or {}
    if mode == 'give' and settings.GiveOnSpawn == false then return end
    if mode == 'remove' and settings.RemoveOnExpire == false then return end

    local preset, system = ResolveKeyPreset()
    if not preset then
        DebugPrint(('Vehicle key system: %s (no actions)'):format(system))
        return
    end

    if preset.Resource and preset.Resource ~= '' and GetResourceState(preset.Resource) ~= 'started' then
        DebugPrint(('Vehicle key resource %s is not started.'):format(preset.Resource))
        return
    end

    if mode == 'give' then
        ExecuteBridgeActions(preset.Give, context)
    elseif mode == 'remove' then
        ExecuteBridgeActions(preset.Remove, context)
    end
end

local function ApplyFuel(vehicle, vehicleData)
    local fuelSettings = Config.Fuel or {}
    local fuel = tonumber(vehicleData.fuel) or tonumber(fuelSettings.DefaultLevel) or 100.0
    local system = string.lower(tostring(fuelSettings.System or 'native'))

    SetVehicleFuelLevel(vehicle, fuel + 0.0)

    if system == 'custom' and type(fuelSettings.Custom) == 'table' then
        ExecuteBridgeActions(fuelSettings.Custom, {
            entity = vehicle,
            netId = VehToNet(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            model = vehicleData.model,
            fuel = fuel
        })
    end
end

local function ApplyVehicleConfiguration(vehicle, vehicleData)
    if not vehicleData then return end

    SetVehicleModKit(vehicle, 0)

    if vehicleData.primaryColor ~= nil or vehicleData.secondaryColor ~= nil then
        local currentPrimary, currentSecondary = GetVehicleColours(vehicle)
        SetVehicleColours(
            vehicle,
            tonumber(vehicleData.primaryColor) or currentPrimary,
            tonumber(vehicleData.secondaryColor) or currentSecondary
        )
    end

    if vehicleData.pearlescentColor ~= nil or vehicleData.wheelColor ~= nil then
        local pearl, wheel = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(
            vehicle,
            tonumber(vehicleData.pearlescentColor) or pearl,
            tonumber(vehicleData.wheelColor) or wheel
        )
    end

    if vehicleData.livery ~= nil and GetVehicleLiveryCount(vehicle) > 0 then
        SetVehicleLivery(vehicle, tonumber(vehicleData.livery) or 0)
    end

    if type(vehicleData.extras) == 'table' then
        for extraId, enabled in pairs(vehicleData.extras) do
            local id = tonumber(extraId)
            if id and DoesExtraExist(vehicle, id) then
                SetVehicleExtra(vehicle, id, enabled and 0 or 1)
            end
        end
    end

    if vehicleData.engineHealth ~= nil then
        SetVehicleEngineHealth(vehicle, tonumber(vehicleData.engineHealth) or 1000.0)
    end

    if vehicleData.bodyHealth ~= nil then
        SetVehicleBodyHealth(vehicle, tonumber(vehicleData.bodyHealth) or 1000.0)
    end

    if vehicleData.dirtLevel ~= nil then
        SetVehicleDirtLevel(vehicle, tonumber(vehicleData.dirtLevel) or 0.0)
    end

    if vehicleData.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, tonumber(vehicleData.windowTint) or 0)
    end

    ApplyFuel(vehicle, vehicleData)
end

local function FinishRental(rentId, expired)
    local rentData = RentedVehicles[rentId]
    if not rentData then return end

    local vehicle = rentData.vehicle
    local exists = vehicle and DoesEntityExist(vehicle)

    HandleVehicleKeys('remove', {
        entity = exists and vehicle or nil,
        netId = rentData.netId,
        plate = rentData.plate,
        model = rentData.model
    })

    if expired and exists then
        if Rental.DisableExpiredVehicle ~= false then
            SetVehicleEngineOn(vehicle, false, true, true)
            SetVehicleUndriveable(vehicle, true)
            SetVehicleDoorsLocked(vehicle, 2)
        end

        if Rental.DeleteExpiredVehicle == true then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
        end
    end

    RentedVehicles[rentId] = nil
    SendNUIMessage({ action = 'rentalStop', id = rentId })
    TriggerServerEvent('lar_rental:finish', rentData.token, rentData.netId)
end

local function CreateRentTimer(rentId)
    CreateThread(function()
        while RentedVehicles[rentId] do
            Wait(500)

            local rentData = RentedVehicles[rentId]
            if not rentData then break end

            if not DoesEntityExist(rentData.vehicle) then
                FinishRental(rentId, false)
                break
            end

            if GetGameTimer() >= rentData.endTime then
                Notify('error', Text.rentalExpired or 'Your rental period has ended.')
                FinishRental(rentId, true)
                break
            end
        end
    end)
end

local function OpenRentMenu(locationIndex)
    if MenuOpen then return end
    if not Config.Locations or not Config.Locations[locationIndex] then return end

    MenuOpen = true
    CurrentLocation = locationIndex
    SetPrompt(false)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openMenu',
        location = locationIndex,
        vehicles = Config.Vehicles or {},
        times = Rental.Times or {},
        pricePerMinute = Rental.DefaultPricePerMinute or 0,
        text = Text,
        ui = Config.UI or {}
    })
end

RegisterNUICallback('close', function(_, cb)
    CloseRentMenu()
    cb({ ok = true })
end)

RegisterNUICallback('rent', function(data, cb)
    if not MenuOpen or not CurrentLocation then
        cb({ ok = false })
        return
    end

    local model = data and tostring(data.model or '') or ''
    local minutes = data and tonumber(data.minutes) or nil

    if model == '' or not minutes then
        Notify('error', Text.invalidSelection or 'Select a valid vehicle and rental duration.')
        cb({ ok = false })
        return
    end

    if not IsSpawnClear(CurrentLocation) then
        Notify('error', Text.spawnBlocked or 'The vehicle spawn area is blocked.')
        cb({ ok = false })
        return
    end

    local location = CurrentLocation
    CloseRentMenu()

    TriggerServerEvent('lar_rental:pay', {
        model = model,
        minutes = minutes,
        location = location
    })

    cb({ ok = true })
end)

RegisterNetEvent('lar_rental:spawnVehicle', function(data)
    if type(data) ~= 'table' or not data.model or not data.minutes or not data.location or not data.rentToken then return end

    local locationIndex = tonumber(data.location)
    local location = Config.Locations and Config.Locations[locationIndex]
    local vehicleData = GetVehicleData(data.model)

    if not location or not location.spawn or not vehicleData then
        Notify('error', Text.vehicleSpawnFailed or 'The rental vehicle could not be created.')
        TriggerServerEvent('lar_rental:spawnFailed', data.rentToken)
        return
    end

    if not IsSpawnClear(locationIndex) then
        Notify('error', Text.spawnBlocked or 'The vehicle spawn area is blocked.')
        TriggerServerEvent('lar_rental:spawnFailed', data.rentToken)
        return
    end

    local hash = LoadModel(data.model)
    if not hash then
        Notify('error', Text.vehicleModelFailed or 'The vehicle model could not be loaded.')
        TriggerServerEvent('lar_rental:spawnFailed', data.rentToken)
        return
    end

    local vehicle = CreateVehicle(
        hash,
        location.spawn.x,
        location.spawn.y,
        location.spawn.z,
        location.spawn.w,
        true,
        true
    )

    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(hash)
        Notify('error', Text.vehicleSpawnFailed or 'The rental vehicle could not be created.')
        TriggerServerEvent('lar_rental:spawnFailed', data.rentToken)
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleNumberPlateText(vehicle, tostring(data.plate or 'ENZO0000'))
    ApplyVehicleConfiguration(vehicle, vehicleData)

    local netId = VehToNet(vehicle)
    if netId and netId ~= 0 then
        SetNetworkIdCanMigrate(netId, true)
        SetNetworkIdExistsOnAllMachines(netId, true)
    end

    if vehicleData.warpIntoVehicle ~= false and Rental.WarpIntoVehicle ~= false then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end

    SetVehicleEngineOn(vehicle, true, true, false)
    Wait(250)

    local plate = GetVehicleNumberPlateText(vehicle)
    local rentId = tostring(data.rentToken)
    local durationMs = math.max(1000, math.floor(tonumber(data.minutes) * 60000))

    HandleVehicleKeys('give', {
        entity = vehicle,
        netId = netId,
        plate = plate,
        model = data.model
    })

    RentedVehicles[rentId] = {
        token = data.rentToken,
        vehicle = vehicle,
        netId = netId,
        plate = plate,
        model = data.model,
        endTime = GetGameTimer() + durationMs
    }

    CreateRentTimer(rentId)
    TriggerServerEvent('lar_rental:spawnConfirmed', data.rentToken, netId, plate)

    SendNUIMessage({
        action = 'rentalStart',
        id = rentId,
        label = vehicleData.label or data.model,
        plate = plate,
        duration = math.floor(durationMs / 1000),
        timerLabel = Text.rentalTimer or 'ENZO RENTAL'
    })

    Notify('success', Text.rentalSuccess or 'Your rental vehicle is ready.')
    SetModelAsNoLongerNeeded(hash)
end)

CreateThread(function()
    for index, location in ipairs(Config.Locations or {}) do
        local model = LoadModel(location.pedModel or 'a_f_y_business_02')

        if model then
            local ped = CreatePed(
                4,
                model,
                location.ped.x,
                location.ped.y,
                location.ped.z - 1.0,
                location.ped.w,
                false,
                true
            )

            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedCanRagdoll(ped, false)
            SetPedDiesWhenInjured(ped, false)
            SetPedFleeAttributes(ped, 0, false)

            Peds[#Peds + 1] = {
                entity = ped,
                location = index
            }

            SetModelAsNoLongerNeeded(model)
        end

        if location.blip then
            local blip = AddBlipForCoord(location.ped.x, location.ped.y, location.ped.z)
            local blipConfig = Config.Blip or {}

            SetBlipSprite(blip, blipConfig.sprite or 225)
            SetBlipColour(blip, blipConfig.colour or 1)
            SetBlipScale(blip, blipConfig.scale or 0.75)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(blipConfig.name or 'ENZO Rental')
            EndTextCommandSetBlipName(blip)

            Blips[#Blips + 1] = blip
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local nearestLocation = nil
        local nearestDistance = math.huge
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, pedData in ipairs(Peds) do
            if DoesEntityExist(pedData.entity) then
                local distance = #(playerCoords - GetEntityCoords(pedData.entity))

                if distance < (tonumber(Interaction.DrawDistance) or 18.0) then
                    sleep = 250
                end

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestLocation = pedData.location
                end
            end
        end

        local canInteract = nearestLocation
            and nearestDistance <= (tonumber(Interaction.Distance) or 2.2)
            and not MenuOpen
            and not IsEntityDead(playerPed)

        if Interaction.HideWhenInVehicle ~= false and IsPedInAnyVehicle(playerPed, false) then
            canInteract = false
        end

        SetPrompt(canInteract == true)

        if canInteract then
            sleep = 0
            if IsControlJustReleased(0, tonumber(Interaction.Control) or 38) then
                OpenRentMenu(nearestLocation)
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)

    for rentId, rentData in pairs(RentedVehicles) do
        HandleVehicleKeys('remove', {
            entity = rentData.vehicle,
            netId = rentData.netId,
            plate = rentData.plate,
            model = rentData.model
        })

        if Rental.DeleteOnResourceStop ~= false and DoesEntityExist(rentData.vehicle) then
            SetEntityAsMissionEntity(rentData.vehicle, true, true)
            DeleteVehicle(rentData.vehicle)
        end

        RentedVehicles[rentId] = nil
    end

    for _, pedData in ipairs(Peds) do
        if DoesEntityExist(pedData.entity) then
            DeleteEntity(pedData.entity)
        end
    end

    for _, blip in ipairs(Blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
