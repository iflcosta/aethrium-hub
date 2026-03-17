function Player.warnClean(self, x)
    if x <= 0 then
		return
	end
	
    self:say("Cleaning in ".. x .. " seconds", TALKTYPE_MONSTER_SAY, false, self)

    local playerName = self:getName()
    addEvent(function()
        local player = Player(playerName)
        if player then
            player:warnClean(x - 5)
        end
    end, 5000)
end

function onThink(interval)
    Game.broadcastMessage('The server will clean in 5 minutes. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 60000, 'The server will clean in 4 minutes. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 120000, 'The server will clean in 3 minutes. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 180000, 'The server will clean in 2 minutes. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 240000, 'The server will clean in 1 minute. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 270000, 'The server will clean in 30 seconds. Please retrieve your items.', MESSAGE_STATUS_WARNING)
    addEvent(function()
        for _, player in ipairs(Game.getPlayers()) do
            player:warnClean(30)
        end
    end, 270000)
    addEvent(cleanMap, 5 * 60 * 1000)
    addEvent(Game.broadcastMessage, 5 * 60 * 1000, 'The server has been cleaned. Enjoy the game. Next cleaning in 3 hours.', MESSAGE_STATUS_WARNING)
    return true
end
