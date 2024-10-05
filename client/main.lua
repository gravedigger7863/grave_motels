local ESX = exports['es_extended']:getSharedObject()

-- Function to spawn ped and blip for each motel
local function spawnMotelPedAndBlip(motel)
    -- Load the ped model
    RequestModel(GetHashKey(motel.pedModel))
    while not HasModelLoaded(GetHashKey(motel.pedModel)) do
        Citizen.Wait(100)
    end

    -- Create the ped at the specified coordinates with heading
    local ped = CreatePed(4, GetHashKey(motel.pedModel), motel.pedCoords.x, motel.pedCoords.y, motel.pedCoords.z, motel.pedCoords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)  -- Make ped invincible
    SetPedCanRagdoll(ped, false)    -- Disable ragdolling
    SetPedFleeAttributes(ped, 0, false)  -- Prevent ped from fleeing
    SetPedCombatAttributes(ped, 17, true) -- Disable fear from combat

    -- Create the blip for the motel
    local blip = AddBlipForCoord(motel.pedCoords.x, motel.pedCoords.y, motel.pedCoords.z)
    SetBlipSprite(blip, motel.blip.blipSprite)
    SetBlipColour(blip, motel.blip.blipColor)
    SetBlipScale(blip, motel.blip.blipScale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(motel.blip.blipName)
    EndTextCommandSetBlipName(blip)
end

-- Spawn peds and blips for all motels
Citizen.CreateThread(function()
    for _, motel in pairs(Config.Motels) do
        spawnMotelPedAndBlip(motel)
    end
end)

-- Function to display help text
local function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Function to handle interaction with motel peds
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for motelId, motel in pairs(Config.Motels) do
            local distance = #(playerCoords - vector3(motel.pedCoords.x, motel.pedCoords.y, motel.pedCoords.z))
            if distance < 2.0 then
                DisplayHelpText("Press ~INPUT_CONTEXT~ to rent a room")
                if IsControlJustReleased(0, 38) then -- 38 is the E key
                    OpenRentMenu(motelId)
                end
            end
        end
    end
end)

-- Function to open ESX context menu for renting rooms
function OpenRentMenu(motelId)
    local motel = Config.Motels[motelId]
    if not motel then return end

    local elements = {}
    for roomId, room in pairs(motel.rooms) do
        table.insert(elements, {
            title = room.name,
            description = string.format("$%d", room.price),
            event = 'grave_motels:rentRoom',
            args = {
                motelId = motelId,
                roomId = roomId
            }
        })
    end

    ESX.CloseContext() -- Close any existing context menus

    ESX.OpenContext("right", elements,
        function(menu, element) -- On Select Function
            if element.event == 'grave_motels:rentRoom' then
                TriggerEvent('grave_motels:rentRoom', element.args)
                ESX.CloseContext()
            end
        end,
        function(menu) -- On Close function
            print("Menu closed.")
        end
    )
end

-- Trigger the server event when a room is selected from the context menu
RegisterNetEvent('grave_motels:rentRoom')
AddEventHandler('grave_motels:rentRoom', function(data)
    local motelId = data.motelId
    local roomId = data.roomId
    if motelId and roomId then
        TriggerServerEvent('grave_motels:rentRoom', motelId, roomId)
    end
end)

-- Function to detect and handle door interaction (client-side)
local function handleDoorInteraction(doorId, playerCoords)
    -- Get door data from the server
    local roomDoor = exports.ox_doorlock:getDoor(doorId)
    
    if roomDoor and roomDoor.coords then
        -- Use the door coordinates and heading provided in the ox_doorlock door data directly
        local doorCoords = vector3(roomDoor.coords.x, roomDoor.coords.y, roomDoor.coords.z)
        local doorHeading = roomDoor.heading or 0.0 -- Use the provided heading or 0 if missing

        -- Get player heading
        local playerHeading = GetEntityHeading(PlayerPedId())

        -- Calculate the difference between the player's heading and the door's heading
        local angleDifference = math.abs(playerHeading - doorHeading)

        -- Determine if the player is inside or outside based on angle difference
        if angleDifference < 90.0 or angleDifference > 270.0 then
            -- Player is inside (facing away from door)
            TriggerServerEvent('grave_motels:teleportOutside')
            print("Player is inside the room. Teleported to the safe spot.")
        else
            -- Player is outside (facing door)
            print("Player is outside the room.")
        end
    else
        print("No door data found for door ID:", doorId)
    end
end

-- Trigger the door interaction when the player unlocks the door
RegisterNetEvent('grave_motels:unlockDoorClient')
AddEventHandler('grave_motels:unlockDoorClient', function(doorId)
    local playerCoords = GetEntityCoords(PlayerPedId())
    handleDoorInteraction(doorId, playerCoords)
end)
