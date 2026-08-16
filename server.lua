--[[
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
]]

local Framework = {
    name = nil,
    object = nil
}

local PendingRentals = {}
local ActiveRentals = {}
local PlayerRentals = {}
local Rental = Config.Rental or {}
local Text = Config.Text or {}


local ConsoleBanner = [[
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
]]

local RequiredResourceName = 'EN-Rental'
local CurrentResourceName = GetCurrentResourceName()

if CurrentResourceName ~= RequiredResourceName then
    print(ConsoleBanner)
    print(('^1[ENZO CODE][Rental] ERROR: Resource name must be exactly "%s". Current name: "%s".^0'):format(RequiredResourceName, CurrentResourceName))
    print('^1[ENZO CODE][Rental] Rename the resource folder back to EN-Rental. Resource stopped.^0')

    CreateThread(function()
        Wait(100)
        StopResource(CurrentResourceName)
    end)

    return
end

local function DebugPrint(...)
    if Config.Debug then
        print('[ENZO CODE][Rental][Server]', ...)
    end
end

local function Notify(src, notifyType, message, title)
    TriggerClientEvent('lar_rental:notify', src, {
        type = notifyType,
        message = message,
        title = title
    })
end

local function ResourceStarted(resource)
    return resource and resource ~= '' and GetResourceState(resource) == 'started'
end

local function LoadFramework(name)
    name = string.lower(tostring(name or ''))

    if name == 'esx' then
        local resource = (Config.FrameworkResources or {}).esx or 'es_extended'
        if not ResourceStarted(resource) then return false end

        local ok, object = pcall(function()
            return exports[resource]:getSharedObject()
        end)

        if (not ok or not object) then
            TriggerEvent('esx:getSharedObject', function(legacyObject)
                object = legacyObject
            end)
        end

        if object then
            Framework.name = 'esx'
            Framework.object = object
            return true
        end
        return false
    end

    if name == 'qb' or name == 'qbcore' then
        local resource = (Config.FrameworkResources or {}).qb or 'qb-core'
        if not ResourceStarted(resource) then return false end

        local ok, object = pcall(function()
            return exports[resource]:GetCoreObject()
        end)

        if (not ok or not object) then
            TriggerEvent('QBCore:GetObject', function(legacyObject)
                object = legacyObject
            end)
        end

        if object then
            Framework.name = 'qb'
            Framework.object = object
            return true
        end
        return false
    end

    if name == 'custom' then
        Framework.name = 'custom'
        Framework.object = Config.CustomFramework or {}
        return true
    end

    return false
end

local function InitializeFramework()
    Framework.name = nil
    Framework.object = nil

    local requested = string.lower(tostring(Config.Framework or 'auto'))
    if requested ~= 'auto' then
        return LoadFramework(requested)
    end

    for _, name in ipairs(Config.FrameworkPriority or { 'esx', 'qb' }) do
        if LoadFramework(name) then
            return true
        end
    end

    return false
end

local function EnsureFramework()
    if Framework.name and Framework.object then
        return true
    end
    return InitializeFramework()
end

local function GetPlayer(src)
    if not EnsureFramework() then return nil end

    if Framework.name == 'esx' then
        return Framework.object.GetPlayerFromId(src)
    end

    if Framework.name == 'qb' then
        return Framework.object.Functions.GetPlayer(src)
    end

    if Framework.name == 'custom' and type(Framework.object.GetPlayer) == 'function' then
        return Framework.object.GetPlayer(src)
    end

    return nil
end

local function NormalizeAccount(account)
    account = string.lower(tostring(account or 'cash'))
    if account == 'money' then return 'cash' end
    return account
end

local function GetMoney(player, account)
    if not player then return 0 end
    account = NormalizeAccount(account)

    if Framework.name == 'esx' then
        if account == 'cash' then
            return tonumber(player.getMoney()) or 0
        end

        local data = player.getAccount(account)
        return data and tonumber(data.money) or 0
    end

    if Framework.name == 'qb' then
        return tonumber(player.PlayerData and player.PlayerData.money and player.PlayerData.money[account]) or 0
    end

    if Framework.name == 'custom' and type(Framework.object.GetMoney) == 'function' then
        return tonumber(Framework.object.GetMoney(player, account)) or 0
    end

    return 0
end

local function RemoveMoney(player, account, amount)
    if not player then return false end
    account = NormalizeAccount(account)
    local reason = (Config.Payment or {}).Reason or 'ENZO CODE vehicle rental'

    if Framework.name == 'esx' then
        if account == 'cash' then
            player.removeMoney(amount, reason)
        else
            player.removeAccountMoney(account, amount, reason)
        end
        return true
    end

    if Framework.name == 'qb' then
        return player.Functions.RemoveMoney(account, amount, reason) ~= false
    end

    if Framework.name == 'custom' and type(Framework.object.RemoveMoney) == 'function' then
        return Framework.object.RemoveMoney(player, account, amount, reason) == true
    end

    return false
end

local function AddMoney(player, account, amount)
    if not player then return false end
    account = NormalizeAccount(account)
    local reason = ('%s refund'):format((Config.Payment or {}).Reason or 'ENZO CODE vehicle rental')

    if Framework.name == 'esx' then
        if account == 'cash' then
            player.addMoney(amount, reason)
        else
            player.addAccountMoney(account, amount, reason)
        end
        return true
    end

    if Framework.name == 'qb' then
        return player.Functions.AddMoney(account, amount, reason) ~= false
    end

    if Framework.name == 'custom' and type(Framework.object.AddMoney) == 'function' then
        return Framework.object.AddMoney(player, account, amount, reason) == true
    end

    return false
end

local function IsValidRentTime(minutes)
    minutes = tonumber(minutes)
    if not minutes then return false end

    for _, rentTime in ipairs(Rental.Times or {}) do
        if tonumber(rentTime) == minutes then
            return true
        end
    end

    return false
end

local function GetVehicleData(model)
    if type(model) ~= 'string' then return nil end

    for _, vehicle in ipairs(Config.Vehicles or {}) do
        if tostring(vehicle.model) == model then
            return vehicle
        end
    end

    return nil
end

local function PlayerHasRental(src)
    local rentals = PlayerRentals[src]
    return rentals and next(rentals) ~= nil
end

local function AddPlayerRental(src, token)
    PlayerRentals[src] = PlayerRentals[src] or {}
    PlayerRentals[src][token] = true
end

local function RemovePlayerRental(src, token)
    if not PlayerRentals[src] then return end
    PlayerRentals[src][token] = nil
    if next(PlayerRentals[src]) == nil then
        PlayerRentals[src] = nil
    end
end

local function ClearActiveRental(token, deleteVehicle)
    local rental = ActiveRentals[token]
    if not rental then return end

    if deleteVehicle and rental.netId and rental.netId ~= 0 then
        local entity = NetworkGetEntityFromNetworkId(rental.netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    RemovePlayerRental(rental.source, token)
    ActiveRentals[token] = nil
end

local function RefundRental(src, pending)
    if not pending then return end

    local player = GetPlayer(src)
    if player then
        AddMoney(player, pending.paidFrom, pending.price)
        Notify(src, 'info', Text.refunded or 'Your rental payment was refunded because the vehicle could not be delivered.')
    end
end

local function ChargeRental(player, price)
    for _, account in ipairs((Config.Payment or {}).Accounts or { 'cash', 'bank' }) do
        local normalized = NormalizeAccount(account)
        if GetMoney(player, normalized) >= price then
            if RemoveMoney(player, normalized, price) then
                return normalized
            end
        end
    end

    return nil
end

local function IsPlayerNearLocation(src, locationIndex)
    if Rental.ValidatePlayerDistance == false then return true end

    local location = Config.Locations and Config.Locations[locationIndex]
    if not location or not location.ped then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        -- Allows compatibility on setups where server-side ped handles are unavailable.
        return true
    end

    local coords = GetEntityCoords(ped)
    if not coords then return true end

    local dx = coords.x - location.ped.x
    local dy = coords.y - location.ped.y
    local dz = coords.z - location.ped.z
    local distance = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))

    return distance <= (tonumber(Rental.ServerValidationDistance) or 12.0)
end

local function GeneratePlate()
    local prefix = string.upper(tostring(Rental.PlatePrefix or 'ENZO')):gsub('[^A-Z0-9]', '')
    local digits = math.max(1, math.min(6, tonumber(Rental.PlateDigits) or 4))
    local maxPrefixLength = math.max(1, 8 - digits)
    prefix = string.sub(prefix, 1, maxPrefixLength)

    local minNumber = 10 ^ (digits - 1)
    local maxNumber = (10 ^ digits) - 1
    local number = math.random(minNumber, maxNumber)

    return ('%s%s'):format(prefix, tostring(number))
end

RegisterNetEvent('lar_rental:pay', function(data)
    local src = source

    if type(data) ~= 'table' then return end
    if not EnsureFramework() then
        Notify(src, 'error', Text.frameworkMissing or 'No supported framework is running. Check Config.Framework.')
        return
    end

    local player = GetPlayer(src)
    if not player then return end

    if PendingRentals[src] then
        Notify(src, 'error', Text.requestPending or 'Your previous rental request is still being processed.')
        return
    end

    if Rental.OneVehiclePerPlayer and PlayerHasRental(src) then
        Notify(src, 'error', Text.alreadyRenting or 'You already have an active rental vehicle.')
        return
    end

    local location = tonumber(data.location)
    if not location or not Config.Locations or not Config.Locations[location] then
        Notify(src, 'error', Text.invalidLocation or 'The selected rental location is invalid.')
        return
    end

    if not IsPlayerNearLocation(src, location) then
        Notify(src, 'error', Text.tooFar or 'You are too far away from the rental desk.')
        return
    end

    local minutes = tonumber(data.minutes)
    if not IsValidRentTime(minutes) then
        Notify(src, 'error', Text.invalidDuration or 'The selected rental duration is invalid.')
        return
    end

    local vehicleData = GetVehicleData(tostring(data.model or ''))
    if not vehicleData then
        Notify(src, 'error', Text.invalidVehicle or 'The selected vehicle is invalid.')
        return
    end

    local pricePerMinute = tonumber(vehicleData.price or Rental.DefaultPricePerMinute or 0) or 0
    local price = math.floor(pricePerMinute * minutes)

    if price <= 0 then
        Notify(src, 'error', Text.invalidPrice or 'The vehicle price is not configured correctly.')
        return
    end

    local paidFrom = ChargeRental(player, price)
    if not paidFrom then
        Notify(src, 'error', Text.insufficientFunds or 'You do not have enough money in the configured payment accounts.')
        return
    end

    local rentToken = ('%s:%s:%s'):format(src, os.time(), math.random(100000, 999999))
    local plate = GeneratePlate()

    PendingRentals[src] = {
        token = rentToken,
        price = price,
        paidFrom = paidFrom,
        createdAt = os.time(),
        minutes = minutes,
        model = vehicleData.model,
        plate = plate
    }

    local paymentMessage = Text.paidAccount or 'Rental payment completed.'
    if paidFrom == 'cash' then paymentMessage = Text.paidCash or paymentMessage end
    if paidFrom == 'bank' then paymentMessage = Text.paidBank or paymentMessage end
    Notify(src, 'success', paymentMessage)

    TriggerClientEvent('lar_rental:spawnVehicle', src, {
        model = vehicleData.model,
        minutes = minutes,
        location = location,
        rentToken = rentToken,
        plate = plate
    })

    local timeout = tonumber(Rental.PendingTimeoutMs) or 30000
    SetTimeout(timeout, function()
        local pending = PendingRentals[src]
        if pending and pending.token == rentToken then
            PendingRentals[src] = nil
            RefundRental(src, pending)
        end
    end)
end)

RegisterNetEvent('lar_rental:spawnConfirmed', function(rentToken, netId, plate)
    local src = source
    local pending = PendingRentals[src]

    if not pending or pending.token ~= rentToken then return end

    PendingRentals[src] = nil

    ActiveRentals[rentToken] = {
        source = src,
        token = rentToken,
        model = pending.model,
        plate = tostring(plate or pending.plate or ''),
        netId = tonumber(netId) or 0,
        expiresAt = os.time() + (pending.minutes * 60)
    }
    AddPlayerRental(src, rentToken)

    SetTimeout((pending.minutes * 60000) + 10000, function()
        local active = ActiveRentals[rentToken]
        if not active then return end
        ClearActiveRental(rentToken, Rental.DeleteExpiredVehicle == true)
    end)
end)

RegisterNetEvent('lar_rental:spawnFailed', function(rentToken)
    local src = source
    local pending = PendingRentals[src]

    if not pending or pending.token ~= rentToken then return end

    PendingRentals[src] = nil
    RefundRental(src, pending)
end)

RegisterNetEvent('lar_rental:finish', function(rentToken, netId)
    local src = source
    local active = ActiveRentals[rentToken]
    if not active or active.source ~= src then return end

    if tonumber(netId) and active.netId ~= 0 and tonumber(netId) ~= active.netId then
        DebugPrint(('Ignored mismatched network id for rental %s.'):format(tostring(rentToken)))
        return
    end

    -- Do not let a client clear OneVehiclePerPlayer while its rental entity is still alive
    -- before the configured rental expiry. Missing/destroyed entities can be cleared early.
    if os.time() < active.expiresAt and active.netId and active.netId ~= 0 then
        local entity = NetworkGetEntityFromNetworkId(active.netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DebugPrint(('Ignored early finish for active rental %s.'):format(tostring(rentToken)))
            return
        end
    end

    ClearActiveRental(rentToken, false)
end)

AddEventHandler('playerDropped', function()
    local src = source
    PendingRentals[src] = nil

    local rentals = PlayerRentals[src]
    if rentals then
        for token in pairs(rentals) do
            ClearActiveRental(token, Rental.DeleteExpiredVehicle == true)
        end
    end

    PlayerRentals[src] = nil
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    print(ConsoleBanner)

    if InitializeFramework() then
        print(('[ENZO CODE][Rental] Framework: %s'):format(string.upper(Framework.name)))
    else
        print('[ENZO CODE][Rental] WARNING: no supported framework detected. Check config.lua.')
    end
end)
