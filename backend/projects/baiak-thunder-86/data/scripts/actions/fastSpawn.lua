local function getSpawnRate()
    
    return 1 
end

local fastSpawn = Action()

function fastSpawn.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local rate = getSpawnRate()
    local text = "                     [Fast Respawn]\n-----------------------------\nThe server's respawn varies based on the number of online players to accommodate your hunt.\n-----------------------------\nThe current server respawn rate is "

    if rate == 1 then
        text = text .. "Normal!"
    else
        text = text .. rate .. "x faster!"
    end

    player:sendTextMessage(MESSAGE_INFO_DESCR, text)
    return true
end

fastSpawn:id(6214)
fastSpawn:register()
