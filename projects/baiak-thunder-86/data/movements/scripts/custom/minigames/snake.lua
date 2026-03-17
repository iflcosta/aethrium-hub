function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return false
    end
  
    if (Game.getStorageValue(SNAKE.freeglobalstorage)) ~= 1 then
        if not player:removeMoney(100000) then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, '[MiniGame] You need 100,000 gold (100k) to play the Snake minigame.')
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        player:teleportTo(SNAKE.controlpos)
        SNAKE.timer(player.uid,1,nil,1000)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, '[MiniGame] Use CTRL + arrows to control the snake. Cost: 100k.')
        SNAKE.generateFood()
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 'Please wait.')
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
    return true
end
