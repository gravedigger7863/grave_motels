Config = {}

-- Configuration for multiple motels
Config.Motels = {
    [1] = {
        name = "Starlite Motel",
        pedModel = "s_m_m_security_01", -- Ped model
        pedCoords = vector4(964.4883, -192.5531, 72.3244, 239.6527), -- Ped spawn location with heading
        blip = {
            blipName = "Starlite Motel",
            blipSprite = 475, -- Blip sprite
            blipColor = 2, -- Blip color
            blipScale = 0.8 -- Blip scale
        },
        doorIds = {2, 3, 4, 5}, -- Door IDs associated with this motel (ensure these match ox_doorlock door IDs)
        rooms = {
            [1] = {
                name = "Room 2",
                price = 100, -- Price for renting
                requiresPayment = true,
                doorId = 2, -- Associated door ID (must match ox_doorlock door ID)
                obtainableItems = {} -- Items handled via metadata
            },
            [2] = {
                name = "Room 3",
                price = 150,
                requiresPayment = true,
                doorId = 3,
                obtainableItems = {}
            },
            [3] = {  -- Changed the key from [2] to [3] to make it unique
                name = "Room 4",
                price = 150,
                requiresPayment = true,
                doorId = 4,
                obtainableItems = {}
            },
            [4] = {  -- Changed the key from [2] to [3] to make it unique
                name = "Room 5",
                price = 150,
                requiresPayment = true,
                doorId = 5,
                obtainableItems = {}
            },
        },
        safeExit = vector4(966.6915, -194.0014, 73.2086, 327.9986) -- Safe exit spot for Starlite Motel
    },
    [2] = {
        name = "Sandy Shores Motel",
        pedModel = "s_m_m_security_02",
        pedCoords = vector4(1824.0, 3680.0, 34.0, 90.0),
        blip = {
            blipName = "Sandy Shores Motel",
            blipSprite = 475,
            blipColor = 3,
            blipScale = 0.8
        },
        doorIds = {104, 105, 106},
        rooms = {
            [1] = {
                name = "Room 201",
                price = 120,
                requiresPayment = true,
                doorId = 104,
                obtainableItems = {}
            },
            [2] = {
                name = "Room 202",
                price = 170,
                requiresPayment = true,
                doorId = 105,
                obtainableItems = {}
            },
            [3] = {
                name = "Room 203",
                price = 220,
                requiresPayment = true,
                doorId = 106,
                obtainableItems = {}
            }
        }
    }
}
