local config = {
    first_room_pos = {x = 216, y = 1261, z = 8}, -- Position of the first room (row 1 column 1)
    distX = 16, -- Distance in X between each room (within the same row)
    distY = 15, -- Distance in Y between each room (within the same column)
    rX = 10, -- Number of columns
    rY = 8 -- Number of rows
}

local function isBusyable(position)
    local player = Tile(position):getTopCreature()
    if player and player:isPlayer() then
        return false
    end

    local tile = Tile(position)
    if not tile or (not tile:isWalkable() and not tile:getGround() and not tile:getGround():isWalkable()) then
        return false
    end

    local items = tile:getItems()
    for i = 1, tile:getItemCount() do
        local item = items[i]
        if not item:isMoveable() and item:getType():isSolid() then
            return false
        end
    end

    return true
end

local function addTrainers(position, arrayPos)
    if not isBusyable(position) then
        for _, pos in ipairs(arrayPos) do
            local trainer = Tile(pos):getTopCreature()
            if not trainer then
                Game.createMonster("Trainer", pos)
                Tile(pos):getTopCreature():getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
            end
        end
    end
end

local function calculatingRoom(uid, position, coluna, linha)
    local player = Player(uid)
    if coluna >= config.rX then
        coluna = 0
        linha = linha < (config.rY - 1) and linha + 1 or false
    end

    if linha then
        local room_pos = {x = position.x + (coluna * config.distX), y = position.y + (linha * config.distY), z = position.z}
        if isBusyable(room_pos) then
            player:teleportTo(room_pos)
            player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
            addTrainers(room_pos, {{x = room_pos.x - 1, y = room_pos.y + 1, z = room_pos.z}, {x = room_pos.x + 1, y = room_pos.y + 1, z = room_pos.z}})
        else
            calculatingRoom(uid, position, coluna + 1, linha)
        end
    else
        player:sendCancelMessage("Unable to find a suitable position for you at the moment.")
    end
end

function onStepIn(creature, item, position, fromPosition)
    if not creature:isPlayer() then
        return false
    end

    local player = creature:getPlayer()
    local STORAGEVALUE_TRAINERS = 95741 -- Replace with your storage value

    if player:getStorageValue(STORAGEVALUE_TRAINERS) - os.time() > 0 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "You need to wait a few seconds before being able to enter the trainers again.")
        player:teleportTo(fromPosition, true)
        return true
    end

    calculatingRoom(player.uid, config.first_room_pos, 0, 0)

    return true
end
