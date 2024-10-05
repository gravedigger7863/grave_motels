-- Add this to your config file
Config.Debug = false  -- Set this to false to disable debug prints

local ESX = exports['es_extended']:getSharedObject()

-- Initialize the rentedRooms table
local rentedRooms = {}

-- Function to display debug messages when Config.Debug is true
local function DebugPrint(message)
    if Config.Debug then
        print(message)
    end
end

-- Function to display the 3D text for the rental timer
local function Draw3DText(coords, text, scale)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)
    
    local adjustedScale = (scale or 0.35) * (1 / (dist / 10))
    if adjustedScale < 0.2 then
        adjustedScale = 0.2
    elseif adjustedScale > 1.0 then
        adjustedScale = 1.0
    end

    SetTextScale(0.0, adjustedScale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(0, 0, 255, 215)  -- Blue text color
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Function to format time
local function formatTime(timeMs)
    local totalSeconds = timeMs / 1000
    local minutes = math.floor(totalSeconds / 60)
    local seconds = math.floor(totalSeconds % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

-- Thread to display the rental timer above doors
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        local currentTime = GetGameTimer()

        for i = #rentedRooms, 1, -1 do
            local room = rentedRooms[i]
            local remainingTime = room.endTime - currentTime

            if remainingTime <= 0 then
                table.remove(rentedRooms, i)
            else
                local timeText = formatTime(remainingTime)
                Draw3DText(room.coords, "Time Left: " .. timeText)
            end
        end
    end
end)

-- Event to start room timer
RegisterNetEvent('grave_motels:startRoomTimer')
AddEventHandler('grave_motels:startRoomTimer', function(doorCoords, duration)
    if doorCoords and duration then
        local startTime = GetGameTimer()
        local endTime = startTime + (duration * 1000)

        rentedRooms[#rentedRooms + 1] = {
            coords = doorCoords,
            endTime = endTime
        }
        DebugPrint("Started timer for door at coords: " .. tostring(doorCoords))
    end
end)

-- Detect the "L" key press globally for unlocking doors with a distance check
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- Detect "L" key press (key code 182)
        if IsControlJustReleased(0, 182) then
            -- Detect the closest door
            local door = exports.ox_doorlock:getClosestDoor()

            if door and door.id then
                local doorId = tonumber(door.id)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local doorCoords = vector3(door.coords.x, door.coords.y, door.coords.z)
                
                -- Check if the player is close enough to the door (within 2 meters)
                local distance = #(playerCoords - doorCoords)

                if distance <= 2.0 then
                    -- Trigger server event to unlock the door
                    TriggerServerEvent('grave_motels:unlockDoor', doorId)
                    DebugPrint("Attempting to unlock door ID: " .. doorId .. " at distance: " .. distance)
                else
                    DebugPrint("Player too far from door ID: " .. doorId .. " at distance: " .. distance)
                end
            else
                DebugPrint("No door found!")
            end
        end
    end
end)


-- Event to teleport player outside when rental expires
RegisterNetEvent('grave_motels:teleportOutside')
AddEventHandler('grave_motels:teleportOutside', function(safeSpot)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, safeSpot.x, safeSpot.y, safeSpot.z)  -- Teleport to the safe spot
end)
