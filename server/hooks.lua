-- Hook to add metadata to motel_key items when they are created
exports.ox_inventory:registerHook('createItem', function(payload)
    if payload.item.name == 'motel_key' then
        -- Ensure metadata is present
        if not payload.metadata then
            payload.metadata = {}
        end

        -- Assign default label if not provided
        payload.metadata.label = payload.metadata.label or 'Motel Key'

        -- Assign default motelId, roomId, doorId only if they are not already set
        payload.metadata.motelId = payload.metadata.motelId or 0
        payload.metadata.roomId = payload.metadata.roomId or 0
        payload.metadata.doorId = payload.metadata.doorId or 0

        -- Dynamically set the description based on metadata
        payload.metadata.description = string.format(
            "Motel ID: %d\nRoom ID: %d\nDoor ID: %d",
            payload.metadata.motelId,
            payload.metadata.roomId,
            payload.metadata.doorId
        )

        -- Debug: Print the metadata to verify
        print(("Created motel_key with metadata: MotelID=%d, RoomID=%d, DoorID=%d"):format(
            payload.metadata.motelId,
            payload.metadata.roomId,
            payload.metadata.doorId
        ))

        return payload.metadata
    end
end, {
    print = true,
    itemFilter = {
        motel_key = true
    }
})
