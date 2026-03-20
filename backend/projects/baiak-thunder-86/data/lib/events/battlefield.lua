BATTLEFIELD = {
    openPortalPosition = Position(1003, 1217, 7),
    waitingRoomPosition = Position(1545, 1070, 4),
    timeOpenPortal = 5, -- In minutes
    timeEventTotal = 30, -- In minutes
    timeRemoveWalls = 30, -- In seconds
    minPlayers = 5,
    maxPlayers = 50,
    level = {
        active = true,
        levelMin = 150,
    },
    reward = {
        itemId = 0,
        count = 0,
    },
    messages = {
        prefix = "[Battlefield] ",
        messageOpen = "The event has started, you have %d minutes to enter the event portal located in the temple!",
        messageStart = "The portal to the event has closed and will start with %d participants! Good luck!",
        messageNoStart = "The event was not started due to lack of participants!",
        messageFinish = "The event is over! Team %s is the event champion!",
        messageWait = "The event portal is open, you have %d minute(s) to enter!",
        messageTimeEnd = "The event was terminated for exceeding the time limit!",
        messageOpenWalls = "The wooden walls have been removed! Good luck!",
    },
    walls = {
        [1] = Position(1546, 1095, 6),
        [2] = Position(1546, 1096, 6),
        [3] = Position(1546, 1097, 6),
        [4] = Position(1546, 1098, 6),
    },
    days = {
        ["Sunday"] = {"15:00"},
        ["Monday"] = {"15:00"},
        ["Tuesday"] = {"15:00"},
        ["Wednesday"] = {"15:00"},
        ["Thursday"] = {"15:00"},
        ["Friday"] = {"15:00"},
        ["Saturday"] = {"15:00"},
    },
    ["red"] = {
        base = Position(1537, 1080, 6),
        outfit = {lookType = 143, lookHead = 94, lookBody = 94, lookLegs = 94, lookFeet = 94},
        players = {},
    },
    ["blue"] = {
        base = Position(1553, 1080, 6),
        outfit = {lookType = 134, lookHead = 88, lookBody = 88, lookLegs = 88, lookFeet = 88},
        players = {},
    },
    idWalls = 3516,
    actionID = 6489,
    storageEventStatus = 34873, -- 0 not started, 1 started, 2 started with blue winner, 3 started with red winner, 4 started without winner
}

function BATTLEFIELD:totalPlayers()
    local total = 0
    for _ in pairs(BATTLEFIELD["red"].players) do
        total = total + 1
    end
    for _ in pairs(BATTLEFIELD["blue"].players) do
        total = total + 1
    end
    return total
end

function BATTLEFIELD:bluePlayers()
    local total = 0
    for _ in pairs(BATTLEFIELD["blue"].players) do
        total = total + 1
    end
    return total
end

function BATTLEFIELD:redPlayers()
    local total = 0
    for _ in pairs(BATTLEFIELD["red"].players) do
        total = total + 1
    end
    return total
end

function BATTLEFIELD:insertPlayer(playerId)
    local player = Player(playerId)
    local team = BATTLEFIELD:redPlayers() > BATTLEFIELD:bluePlayers() and "blue" or "red"
    BATTLEFIELD[team].players[player:getId()] = {}
    player:sendCancelMessage(BATTLEFIELD.messages.prefix .. "You joined the " .. team .. " team.")
    player:setOutfit(BATTLEFIELD[team].outfit)
    player:setStorageValue(STORAGEVALUE_EVENTS, 1)
    player:teleportTo(BATTLEFIELD.waitingRoomPosition)
    player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
    return true
end

function BATTLEFIELD:removePlayer(playerId)
    for k, _ in pairs(BATTLEFIELD["red"].players) do
        if k == playerId then
            BATTLEFIELD["red"].players[k] = nil
        end
    end
    for k, _ in pairs(BATTLEFIELD["blue"].players) do
        if k == playerId then
            BATTLEFIELD["blue"].players[k] = nil
        end
    end
end

function BATTLEFIELD:checkTeleport()
    local tile = Tile(BATTLEFIELD.openPortalPosition)
    if tile then
        local item = tile:getItemById(1387)
        if item then
            item:getPosition():sendMagicEffect(CONST_ME_POFF)
            item:remove()
            if BATTLEFIELD:totalPlayers() >= BATTLEFIELD.minPlayers then
                Game.broadcastMessage(BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageStart):format(BATTLEFIELD:totalPlayers()))
                Game.setStorageValue(BATTLEFIELD.storageEventStatus, 1)
                addEvent(function()
                    Game.broadcastMessage(BATTLEFIELD.messages.prefix .. BATTLEFIELD.messages.messageOpenWalls)
                    BATTLEFIELD:checkWalls()
                end, BATTLEFIELD.timeRemoveWalls * 1000)
                addEvent(function()
                    if Game.getStorageValue(BATTLEFIELD.storageEventStatus) ~= 0 then
                        Game.broadcastMessage(BATTLEFIELD.messages.prefix .. BATTLEFIELD.messages.messageTimeEnd)
                        Game.setStorageValue(BATTLEFIELD.storageEventStatus, 4)
                        BATTLEFIELD:finishEvent()
                    end
                end, BATTLEFIELD.timeEventTotal * 60 * 1000)
                BATTLEFIELD:startEvent()
            else
                Game.broadcastMessage(BATTLEFIELD.messages.prefix .. BATTLEFIELD.messages.messageNoStart)
                Game.setStorageValue(BATTLEFIELD.storageEventStatus, 0)
                BATTLEFIELD:finishEvent()
            end
        else
            Game.broadcastMessage(BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageOpen):format(BATTLEFIELD.timeOpenPortal))
            addEvent(Game.broadcastMessage, (BATTLEFIELD.timeOpenPortal - 3) * 60 * 1000, BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageWait):format(BATTLEFIELD.timeOpenPortal - 2))
            addEvent(Game.broadcastMessage, (BATTLEFIELD.timeOpenPortal - 1) * 60 * 1000, BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageWait):format(BATTLEFIELD.timeOpenPortal - 4))
            local teleport = Game.createItem(1387, 1, BATTLEFIELD.openPortalPosition)
            if teleport then
                teleport:setActionId(BATTLEFIELD.actionID)
            end
            addEvent(function()
                BATTLEFIELD:checkTeleport()
            end, BATTLEFIELD.timeOpenPortal * 60 * 1000)
            Game.setStorageValue(BATTLEFIELD.storageEventStatus, 0)
        end
    end
end

function BATTLEFIELD:checkStatus()
    local blueTeam = BATTLEFIELD:bluePlayers()
    local redTeam = BATTLEFIELD:redPlayers()
    if blueTeam > 0 and redTeam == 0 then
        Game.broadcastMessage(BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageFinish):format("blue"))
        Game.setStorageValue(BATTLEFIELD.storageEventStatus, 2)
        BATTLEFIELD:finishEvent()
    elseif redTeam > 0 and blueTeam == 0 then
        Game.broadcastMessage(BATTLEFIELD.messages.prefix .. (BATTLEFIELD.messages.messageFinish):format("red"))
        Game.setStorageValue(BATTLEFIELD.storageEventStatus, 3)
        BATTLEFIELD:finishEvent()
    end
end

function BATTLEFIELD:startEvent()
    if Game.getStorageValue(BATTLEFIELD.storageEventStatus) >= 1 then
        local teams = {"blue", "red"}
        for _, team in ipairs(teams) do
            for playerId in pairs(BATTLEFIELD[team].players) do
                local player = Player(playerId)
                player:teleportTo(BATTLEFIELD[team].base)
                player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
                player:sendTextMessage(MESSAGE_INFO_DESCR, BATTLEFIELD.messages.prefix .. "In " .. BATTLEFIELD.timeRemoveWalls .. " seconds, the wooden walls will be removed!")
            end
        end
    end
end

function BATTLEFIELD:finishEvent()
    local gameStatus = Game.getStorageValue(BATTLEFIELD.storageEventStatus)
    if gameStatus == 0 or gameStatus == 4 then
        local teams = {"blue", "red"}
        for _, team in ipairs(teams) do
            for playerId in pairs(BATTLEFIELD[team].players) do
                local player = Player(playerId)
                player:teleportTo(player:getTown():getTemplePosition())
                player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
                player:setStorageValue(STORAGEVALUE_EVENTS, 0)
                BATTLEFIELD:removePlayer(player:getId())
            end
        end
    elseif gameStatus == 2 or gameStatus == 3 then
        local teams = {"blue", "red"}
        for _, team in ipairs(teams) do
            for playerId in pairs(BATTLEFIELD[team].players) do
                local player = Player(playerId)
                if gameStatus == 2 or gameStatus == 3 then
                    player:addItem(BATTLEFIELD.reward.itemId, BATTLEFIELD.reward.count)
                    player:addEventPoints("boss", 100)
                    player:addEventPoints("task", 100)
                end
                player:teleportTo(player:getTown():getTemplePosition())
                player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
                player:setStorageValue(STORAGEVALUE_EVENTS, 0)
                BATTLEFIELD:removePlayer(player:getId())
            end
        end
    end
    Game.setStorageValue(BATTLEFIELD.storageEventStatus, 0)
    BATTLEFIELD:checkWalls()
end

function BATTLEFIELD:checkWalls()
    for _, wallPos in ipairs(BATTLEFIELD.walls) do
        local tile = Tile(wallPos)
        if tile then
            local item = tile:getItemById(BATTLEFIELD.idWalls)
            if item then
                item:getPosition():sendMagicEffect(CONST_ME_POFF)
                item:remove()
            else
                local wall = Game.createItem(BATTLEFIELD.idWalls, 1, wallPos)
                wall:getPosition():sendMagicEffect(CONST_ME_POFF)
            end
        end
    end
end
