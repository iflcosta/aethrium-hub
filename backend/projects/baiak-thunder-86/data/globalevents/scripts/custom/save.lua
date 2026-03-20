function Player.warnSave(self, x)
    if x <= 0 then
        return
    end
    
    self:say("Server save in ".. x .. " seconds", TALKTYPE_MONSTER_SAY, false, self)

    local playerName = self:getName()
    addEvent(function()
        local player = Player(playerName)
        if player then
            player:warnSave(x - 5)
        end
    end, 5000)
end


function onThink(interval)
    Game.broadcastMessage('Server will save in 5 minutes.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 60000, 'Server will save in 4 minutes.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 120000, 'Server will save in 3 minutes.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 180000, 'Server will save in 2 minutes.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 240000, 'Server will save in 1 minute.', MESSAGE_STATUS_WARNING)
    addEvent(Game.broadcastMessage, 270000, 'Server will save in 30 seconds.', MESSAGE_STATUS_WARNING)
    addEvent(function()
        for pid, player in ipairs(Game.getPlayers()) do
            player:warnSave(30)
        end
    end, 270000)
    addEvent(saveServer, 5 * 60 * 1000)
    addEvent(Game.broadcastMessage, 5 * 60 * 1000, 'Server has been saved. Have a good game.', MESSAGE_STATUS_WARNING)
    return true
end
