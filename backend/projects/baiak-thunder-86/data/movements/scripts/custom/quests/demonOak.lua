local config = {
    centerPos = Position(1178, 1027, 7),
    enterPos = Position(1177, 1031, 7),
    exitPos = Position(1179, 1027, 7), -- Specify the exit position
    storageGlobal = 95741,
    storageDone = 63578,
    qntMaxDay = 5,
}

function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player or creature:isMonster() then
        creature:teleportTo(fromPosition, true)
        return true
    end

    if item.actionid == 26741 then
        if Game.getStorageValue(config.storageGlobal) == nil or Game.getStorageValue(config.storageGlobal) < 0 then
            Game.setStorageValue(config.storageGlobal, 0)
        end

        if Game.getStorageValue(config.storageGlobal) >= config.qntMaxDay then
            player:sendCancelMessage("This quest can only be done ".. config.qntMaxDay .." times per day.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        if player:getItemCount(8293) == 0 then
            player:sendCancelMessage("You need a ".. ItemType(8293):getName() .." to enter.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        if player:getStorageValue(config.storageDone) >= 1 then
            player:sendCancelMessage("You have already completed this quest.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        local spec = Game.getSpectators(config.centerPos, false, false, 0, 10, 0, 9)
        if #spec > 0 then
            player:sendCancelMessage("There is already a player inside the quest.")
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        Game.setStorageValue(config.storageGlobal, Game.getStorageValue(config.storageGlobal) + 1)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:teleportTo(config.enterPos)
        player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

    elseif item.actionid == 26742 then
        player:teleportTo(config.exitPos)
        player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
    end

    return true
end
