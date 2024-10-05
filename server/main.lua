local ESX = exports['es_extended']:getSharedObject()

-- Table to keep track of players' rented rooms and their rental expiration time
local playerRooms = {}

-- Function to remove the motel key from the player after the rental time expires and teleport them outside
local function removeMotelKeyAfterTime(src, motelId, roomId, rentalDuration)
    Citizen.CreateThread(function()
        Citizen.Wait(rentalDuration * 1000) -- Wait for the rental duration (in milliseconds)

        if playerRooms[src] and playerRooms[src].roomId == roomId then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                -- Remove the motel key from the player's inventory
                xPlayer.removeInventoryItem('motel_key', 1)
                TriggerClientEvent('esx:showNotification', src, 'Your room rental has expired, and the key has been removed.')

                -- Get the door data using ox_doorlock API
                local roomDoor = exports.ox_doorlock:getDoor(Config.Motels[motelId].rooms[roomId].doorId)

                if roomDoor then
                    -- Just send the door data to the client to handle the rest
                    print("Door Data: ", json.encode(roomDoor))
                    TriggerClientEvent('grave_motels:processDoorOnClient', src, roomDoor)
                else
                    print("Door data not found for room:", roomId)
                end
            end
            playerRooms[src] = nil -- Remove the player from the playerRooms table
        end
    end)
end

-- Event to handle room renting
RegisterServerEvent('grave_motels:rentRoom')
AddEventHandler('grave_motels:rentRoom', function(motelId, roomId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local motel = Config.Motels[motelId]
    
    if not motel then 
        TriggerClientEvent('esx:showNotification', src, 'Invalid motel.')
        print(("Player %d attempted to rent an invalid motel ID: %d"):format(src, motelId))
        return 
    end

    local room = motel.rooms[roomId]
    if not room then 
        TriggerClientEvent('esx:showNotification', src, 'Invalid room.')
        print(("Player %d attempted to rent an invalid room ID: %d in motel ID: %d"):format(src, roomId, motelId))
        return 
    end

    if room.requiresPayment then
        if xPlayer.getMoney() < room.price then
            TriggerClientEvent('esx:showNotification', src, 'You do not have enough money.')
            print(("Player %d does not have enough money to rent room ID: %d in motel ID: %d"):format(src, roomId, motelId))
            return
        else
            xPlayer.removeMoney(room.price)
            print(("Player %d paid $%d to rent room ID: %d in motel ID: %d"):format(src, room.price, roomId, motelId))
        end
    end

    -- Remove old key if exists
    if playerRooms[src] then
        local oldRoom = playerRooms[src]
        if oldRoom.roomId then
            -- Remove the old key
            xPlayer.removeInventoryItem('motel_key', 1)
            print(("Player %d had an existing key for room ID: %d and it was removed"):format(src, oldRoom.roomId))
        end
    end

    -- Set the rental duration in seconds
    local rentalDuration = 30 -- Rental time is now 30 seconds

    -- Grant new key with metadata
    playerRooms[src] = {motelId = motelId, roomId = roomId}
    TriggerClientEvent('esx:showNotification', src, 'You have rented ' .. room.name)
    print(("Player %d has rented room ID: %d in motel ID: %d"):format(src, roomId, motelId))
    
    -- Grant motel_key with metadata
    local keyMetadata = {
        motelId = motelId,
        roomId = roomId,
        doorId = room.doorId
    }
    
    -- Debug: Print key metadata being added
    print(("Adding motel_key to player %d with metadata: MotelID=%d, RoomID=%d, DoorID=%d"):format(
        src, keyMetadata.motelId, keyMetadata.roomId, keyMetadata.doorId
    ))
    
    exports.ox_inventory:AddItem(src, 'motel_key', 1, keyMetadata)

    -- Get door data and pass coordinates to client
    local doorData = exports.ox_doorlock:getDoor(room.doorId)
    if doorData then
        local coords = doorData.coords
        if coords then
            TriggerClientEvent('grave_motels:startRoomTimer', src, coords, rentalDuration)
        else
            print("No door coordinates found for door ID:", room.doorId)
        end
    end

    -- Set a timer to remove the key after the rental duration expires
    removeMotelKeyAfterTime(src, motelId, roomId, rentalDuration)

    Wait(3000) -- Wait for 3 seconds before showing the next notification
    TriggerClientEvent('esx:showNotification', src, 'Lock/Unlock your room with the L key.')
end)

-- Event to unlock the door (triggered by the client when pressing the L key)
RegisterServerEvent('grave_motels:unlockDoor')
AddEventHandler('grave_motels:unlockDoor', function(doorId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then
        print(("Player %d not found while attempting to unlock door ID: %d"):format(src, doorId))
        return
    end

    print(("Unlock request received for door ID: %d from player %d"):format(doorId, src))  -- Log when the unlock request is received

    -- Check if player has the key for the door
    local inventory = exports.ox_inventory:Search(src, 'slots', 'motel_key')
    local hasKey = false

    if inventory then
        for _, item in pairs(inventory) do
            if item.metadata and tonumber(item.metadata.doorId) == tonumber(doorId) then
                hasKey = true
                print(("Player %d has the key for door ID: %d"):format(src, doorId))  -- Log if the player has the key
                break
            end
        end
    end

    if hasKey then
        -- Unlock the door
        TriggerEvent('ox_doorlock:setState', doorId, 0) -- 0 unlocks the door
        print(("Player %d unlocked door ID: %d"):format(src, doorId))  -- Log the unlocking action
    else
        print(("Player %d attempted to unlock door ID: %d but does not have the key"):format(src, doorId))
        TriggerClientEvent('esx:showNotification', src, 'You do not have the key for this door.')
    end
end)

-- Server callback to check if player has a key for a specific door
ESX.RegisterServerCallback('grave_motels:hasKeyForDoor', function(source, cb, doorId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        print(("Server callback error: Player %d not found"):format(source))
        cb(false)
        return
    end

    local inventory = exports.ox_inventory:Search(source, 'slots', 'motel_key')
    
    if inventory then
        for _, item in pairs(inventory) do
            if item.metadata and tonumber(item.metadata.doorId) == tonumber(doorId) then
                cb(true)
                return
            end
        end
    end

    cb(false)
end)
