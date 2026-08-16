--[[
███████╗███╗   ██╗███████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝████╗  ██║╚══███╔╝██╔═══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
█████╗  ██╔██╗ ██║  ███╔╝ ██║   ██║    ██║     ██║   ██║██║  ██║█████╗
██╔══╝  ██║╚██╗██║ ███╔╝  ██║   ██║    ██║     ██║   ██║██║  ██║██╔══╝
███████╗██║ ╚████║███████╗╚██████╔╝    ╚██████╗╚██████╔╝██████╔╝███████╗
╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝      ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

               DISCORD • https://discord.gg/HPEAWNB52w
]]

Config = {}

-- auto | esx | qb | custom
Config.Framework = 'auto'
Config.FrameworkPriority = { 'esx', 'qb' }
Config.FrameworkResources = {
    esx = 'es_extended',
    qb = 'qb-core'
}
Config.Debug = false

-- Used only when Config.Framework = 'custom'.
-- Replace these functions with your own framework/economy bridge.
Config.CustomFramework = {
    GetPlayer = function(source)
        return nil
    end,
    GetMoney = function(player, account)
        return 0
    end,
    RemoveMoney = function(player, account, amount, reason)
        return false
    end,
    AddMoney = function(player, account, amount, reason)
        return false
    end
}

Config.Payment = {
    -- The resource checks accounts in this order.
    Accounts = { 'cash', 'bank' },
    Reason = 'ENZO CODE vehicle rental'
}

Config.Rental = {
    Times = { 5, 10, 15, 20, 30, 45, 60 },
    DefaultPricePerMinute = 60,
    OneVehiclePerPlayer = false,
    SpawnClearRadius = 3.0,
    PendingTimeoutMs = 30000,
    ValidatePlayerDistance = true,
    ServerValidationDistance = 12.0,

    -- Vehicle behavior after the timer finishes.
    DeleteExpiredVehicle = false,
    DisableExpiredVehicle = true,
    DeleteOnResourceStop = true,
    WarpIntoVehicle = true,

    -- GTA plates are limited; keep the prefix short.
    PlatePrefix = 'ENZO',
    PlateDigits = 4
}

Config.Interaction = {
    Distance = 2.2,
    DrawDistance = 18.0,
    Control = 38, -- E
    KeyLabel = 'E',
    HideWhenInVehicle = true
}

Config.Blip = {
    sprite = 225,
    colour = 1,
    scale = 0.75,
    name = 'ENZO Rental'
}

-- Vehicle key bridge.
-- System: auto | none | qb-vehiclekeys | custom
-- "custom" supports client events, server events and exports without editing client.lua.
Config.VehicleKeys = {
    System = 'auto',
    GiveOnSpawn = true,
    RemoveOnExpire = true,

    -- Auto mode uses the first started resource from this list.
    AutoOrder = { 'qb-vehiclekeys' },

    Presets = {
        ['qb-vehiclekeys'] = {
            Resource = 'qb-vehiclekeys',
            Give = {
                { Type = 'client_event', Name = 'vehiclekeys:client:SetOwner', Args = { 'plate' } },
                { Type = 'client_event', Name = 'qb-vehiclekeys:client:AddNewVehicle', Args = {} }
            },
            Remove = {}
        }
    },

    Custom = {
        Resource = '',
        Give = {
            -- Example:
            -- { Type = 'client_event', Name = 'mykeys:client:give', Args = { 'plate', 'netId' } },
            -- { Type = 'server_event', Name = 'mykeys:server:give', Args = { 'plate', 'netId' } },
            -- { Type = 'export', Resource = 'mykeys', Name = 'GiveKeys', Args = { 'entity', 'plate' } },
        },
        Remove = {
            -- Example:
            -- { Type = 'client_event', Name = 'mykeys:client:remove', Args = { 'plate', 'netId' } },
        }
    }
}

-- Optional fuel bridge.
-- System: native | custom
Config.Fuel = {
    System = 'native',
    DefaultLevel = 100.0,
    Custom = {
        -- Example export action:
        -- Type = 'export', Resource = 'LegacyFuel', Name = 'SetFuel', Args = { 'entity', 'fuel' }
    }
}

Config.UI = {
    Brand = 'ENZO RENTAL',
    BrandShort = 'ER',
    Credit = 'ENZO CODE',
    Discord = 'https://discord.gg/HPEAWNB52w',
    Currency = '$',
    Locale = 'en-US',
    ShowVehicleImages = true,

    -- Solid red/black theme. No gradients are used in the interface.
    Theme = {
        accent = '#e11d2e',
        accentHover = '#f02b3c',
        accentSoft = 'rgba(225, 29, 46, 0.12)',
        background = '#09090b',
        panel = '#0f0f12',
        surface = '#151519',
        surfaceHover = '#1a1a1f',
        footer = '#0b0b0e',
        border = '#29292f',
        borderStrong = '#3a3a43',
        text = '#f5f5f7',
        muted = '#9a9aa4',
        mutedDark = '#6f6f78',
        danger = '#ff4d5d',
        success = '#38c878'
    }
}

Config.Text = {
    interact = 'Press E to open ENZO Rental',
    menuTitle = 'Rent a vehicle',
    menuSubtitle = 'Choose a vehicle and rental duration.',
    fleetLabel = 'Rental fleet',
    vehicleLabel = 'Vehicle',
    durationLabel = 'Rental duration',
    totalLabel = 'Total price',
    rentButton = 'Rent vehicle',
    closeButton = 'Close',
    perMinute = '/ min',
    minute = 'min',
    allCategories = 'All',
    selectedVehicle = 'Selected vehicle',
    selectedDuration = 'Duration',
    noSelection = 'Not selected',
    paymentHint = 'Payment account is selected automatically.',
    statusLabel = 'RENT DESK',
    statusValue = 'ONLINE',
    selectedBadge = 'SELECTED',
    vehiclesCount = 'vehicles',
    vehicleCount = 'vehicle',
    noVehicles = 'No vehicles are available in this category.',
    noVehicle = 'NO VEHICLE',
    chooseVehicleHint = 'Choose a vehicle from the list.',
    notificationSuccess = 'Success',
    notificationError = 'Error',
    notificationInfo = 'Notice',
    vehicleSpecs = 'Vehicle details',
    seats = 'seats',
    priceRate = 'Price rate',

    spawnBlocked = 'The vehicle spawn area is blocked.',
    invalidSelection = 'Select a valid vehicle and rental duration.',
    invalidLocation = 'The selected rental location is invalid.',
    invalidDuration = 'The selected rental duration is invalid.',
    invalidVehicle = 'The selected vehicle is invalid.',
    invalidPrice = 'The vehicle price is not configured correctly.',
    tooFar = 'You are too far away from the rental desk.',
    alreadyRenting = 'You already have an active rental vehicle.',
    requestPending = 'Your previous rental request is still being processed.',
    insufficientFunds = 'You do not have enough money in the configured payment accounts.',
    paidCash = 'Rental payment was taken from cash.',
    paidBank = 'Rental payment was taken from bank.',
    paidAccount = 'Rental payment completed.',
    refunded = 'Your rental payment was refunded because the vehicle could not be delivered.',
    vehicleSpawnFailed = 'The rental vehicle could not be created.',
    vehicleModelFailed = 'The vehicle model could not be loaded.',
    rentalSuccess = 'Your rental vehicle is ready.',
    rentalExpired = 'Your rental period has ended.',
    rentalTimer = 'ENZO RENTAL',
    frameworkMissing = 'No supported framework is running. Check Config.Framework.'
}

-- Edit, remove or add rental vehicles here.
-- Optional fields: image, seats, fuel, primaryColor, secondaryColor, livery, extras, engineHealth, bodyHealth, dirtLevel.
Config.Vehicles = {
    {
        label = 'Blista', model = 'blista', price = 45, category = 'Compact', seats = 4,
        description = 'Economical city car for short trips.', image = '', fuel = 100.0
    },
    {
        label = 'Dilettante', model = 'dilettante', price = 50, category = 'Compact', seats = 4,
        description = 'Quiet hybrid for daily driving.', image = '', fuel = 100.0
    },
    {
        label = 'Asea', model = 'asea', price = 55, category = 'Sedan', seats = 4,
        description = 'Affordable four-door sedan.', image = '', fuel = 100.0
    },
    {
        label = 'Primo', model = 'primo', price = 60, category = 'Sedan', seats = 4,
        description = 'Comfortable and practical.', image = '', fuel = 100.0
    },
    {
        label = 'Sultan', model = 'sultan', price = 85, category = 'Sport', seats = 4,
        description = 'Responsive all-round performance.', image = '', fuel = 100.0
    },
    {
        label = 'Buffalo', model = 'buffalo', price = 95, category = 'Sport', seats = 4,
        description = 'Fast four-door sports sedan.', image = '', fuel = 100.0
    },
    {
        label = 'Schafter', model = 'schafter2', price = 100, category = 'Executive', seats = 4,
        description = 'Premium comfort and power.', image = '', fuel = 100.0
    },
    {
        label = 'Baller', model = 'baller', price = 110, category = 'SUV', seats = 4,
        description = 'Premium SUV for city travel.', image = '', fuel = 100.0
    },
    {
        label = 'Granger', model = 'granger', price = 120, category = 'SUV', seats = 8,
        description = 'Large SUV with extra passenger space.', image = '', fuel = 100.0
    },
    {
        label = 'Bison', model = 'bison', price = 90, category = 'Utility', seats = 6,
        description = 'Reliable pickup for heavy use.', image = '', fuel = 100.0
    },
    {
        label = 'Speedo', model = 'speedo', price = 80, category = 'Utility', seats = 4,
        description = 'Cargo van with useful capacity.', image = '', fuel = 100.0
    },
    {
        label = 'Faggio', model = 'faggio', price = 30, category = 'Motorcycle', seats = 2,
        description = 'Low-cost scooter for short trips.', image = '', fuel = 100.0
    },
    {
        label = 'BF400', model = 'bf400', price = 65, category = 'Motorcycle', seats = 2,
        description = 'Lightweight and agile off-road bike.', image = '', fuel = 100.0
    },
    {
        label = 'Bati 801', model = 'bati', price = 85, category = 'Motorcycle', seats = 2,
        description = 'Quick road bike for experienced riders.', image = '', fuel = 100.0
    },
    {
        label = 'Neon', model = 'neon', price = 135, category = 'Electric', seats = 4,
        description = 'Fast premium electric sedan.', image = '', fuel = 100.0
    }
}

Config.Locations = {
    {
        ped = vector4(-1031.794, -2734.543, 20.169, 100.553),
        spawn = vector4(-1028.898, -2729.124, 20.192, 241.033),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(-676.061, 299.331, 82.044, 162.842),
        spawn = vector4(-679.481, 292.109, 82.047, 88.803),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(-902.335, -144.334, 41.884, 143.272),
        spawn = vector4(-908.056, -151.990, 41.884, 293.459),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(-614.075, -943.475, 21.946, 107.035),
        spawn = vector4(-620.343, -934.576, 22.117, 11.236),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(-62.741, -207.610, 45.809, 169.407),
        spawn = vector4(-67.042, -214.676, 45.445, 149.508),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(210.298, -1402.630, 29.317, 149.380),
        spawn = vector4(204.698, -1408.758, 29.176, 228.779),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(747.636, 117.676, 78.617, 236.996),
        spawn = vector4(751.897, 113.269, 78.783, 144.786),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(1853.496, 2583.550, 45.672, 286.567),
        spawn = vector4(1860.329, 2587.174, 45.672, 356.093),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(107.267, 6612.472, 31.986, 227.777),
        spawn = vector4(115.097, 6607.883, 31.900, 233.834),
        pedModel = 'a_f_y_business_02', blip = true
    },
    {
        ped = vector4(215.760, -810.120, 30.730, 157.000),
        spawn = vector4(222.110, -804.450, 30.690, 339.000),
        pedModel = 'a_f_y_bevhills_02', blip = true
    }
}
