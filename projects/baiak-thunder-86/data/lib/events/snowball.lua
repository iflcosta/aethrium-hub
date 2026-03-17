SNOWBALL = {
    -- Storage values
    STORAGEVALUE_EVENTS = 10110, -- Storage for event participation
    -- Text configurations
    throwCommand = "throw", -- !snowball throw
    prefix = "[SnowBall] ",
    -- Portuguese messages
    mensagemEventoFaltaPlayer = "Evento cancelado. Precisa de %d jogadores.",
    mensagemInicioEvento = "O evento comecou!",
    mensagemEsperandoIniciar = "Aguardando %d minuto(s). Precisa de mais %d jogador(es).",
    mensagemEventoAberto = "O evento foi aberto! Va ao temple para participar.",
    -- English messages
    messageHit = "You've been hit by player %s and lost -%d point(s).\nTotal: %d point(s)",
    messageHitOpponent = "You've hit player %s and gained +%d point(s).\nTotal: %d point(s)",
    messageLeader = "You are now the leader of the SnowBall ranking, congratulations!",
    messageLostLeader = "You've just lost the first place!",
    messageEventEnded = "The event has ended.",
    messageBallsLeft = "There are still %d snowballs left.",
    messageNoBalls = "You don't have any snowballs.",
    messageEventCancelled = "The event was canceled due to insufficient players.",
    messageEventStarted = "The event has closed. The game has started.",
    messageWaitingToStart = "Waiting for %d minute(s) and %d player(s) for the game to start.",
    messageMinutesLeft = "%d minute(s) left until the game starts.",
    messageEventOpened = "The event has been opened, go to the temple to participate.",
    messageBoughtBalls = "You've just bought %d snowballs for %d.\nYou have %d snowballs left.\nYou have %d point(s).",
    messageFailedBuy = "You don't have %d point(s).",
    messageMinBuy = "You can only buy snowballs with a minimum of 30 balls.",
    -- Position configurations
    arenaPos = {{x = 1525, y = 884, z = 7}, {x = 1580, y = 930, z = 7}},
    waitingPos = {x = 1553, y = 855, z = 7},
    tpEnterEventPos = Position(1003, 1217, 7),
    posTpEntrarEvento = {x = 1003, y = 1217, z = 7}, -- Portuguese alias
    -- Portuguese configs
    muniInicial = 100, -- Initial ammo (portuguese)
    duracaoEvento = 20, -- Event duration in minutes (portuguese)
    duracaoEspera = 5, -- Waiting duration in minutes (portuguese)
    -- Ammunition configurations
    ammoPrice = 1,
    ammoQuantity = 100, -- Amount gained per purchase.
    initialAmmo = 100, -- Starts with 100.
    ammoDeath = 100, -- Set to 0 to disable.
    ammoSpeed = 150, -- Speed of each shot.
    ammoInfinite = false,
    ammoExhaust = 1, -- Seconds to wait before using snowball throw again.
    ammoDistance = 5,
    -- Prize configurations
    prizes = {
        [1] = {[9020] = 5}, -- First Place
    },
    -- General configurations
    eventDuration = 20,
    waitingDuration = 5,
    minPlayers = 5,
    maxPlayers = 50,
    level = {
        active = true,
        minLevel = 150,
    },
    hitPoints = 1,
    lossPoints = 1,
    days = {
        ["Sunday"] = {"10:00"},
        ["Monday"] = {"10:00"},
        ["Tuesday"] = {"23:12"},
        ["Wednesday"] = {"10:00"},
        ["Thursday"] = {"10:00"},
        ["Friday"] = {"10:00"},
        ["Saturday"] = {"10:00"},
    },
    -- Do not modify below this line
    -- Frozen bodies configurations
    frozenBodies = {
        [0] = {[0] = {7303}, [1] = {7306}, [2] = {7303}, [3] = {7306}},
        [1] = {[0] = {7305, 7307, 7309, 7311}, [1] = {7308, 7310, 7312}, [2] = {7305, 7307, 7309, 7311}, [3] = {7308, 7310, 7312}},
    },
    directions = {
        [0] = {dirPos = {x = 0, y = -1}},
        [1] = {dirPos = {x = 1, y = 0}},
        [2] = {dirPos = {x = 0, y = 1}},
        [3] = {dirPos = {x = -1, y = 0}},
    }
}

CACHE_PLAYERS = {}
CACHE_AREA_POSITIONS = {}

function loadEvent()
    for newX = SNOWBALL.arenaPos[1].x, SNOWBALL.arenaPos[2].x do
        for newY = SNOWBALL.arenaPos[1].y, SNOWBALL.arenaPos[2].y do
            local areaPos = {x = newX, y = newY, z = SNOWBALL.arenaPos[1].z}
            if getTileThingByPos(areaPos).itemid == 0 then
                print("".. SNOWBALL.prefix .."(x = " .. areaPos.x .. " - y = " .. areaPos.y .." - z = " .. areaPos.z .. "), it was not possible to load these positions.")
                return false
            elseif isWalkable(areaPos) then
                table.insert(CACHE_AREA_POSITIONS, areaPos)
            end
        end
    end
    
    if getTileThingByPos(SNOWBALL.waitingPos).itemid == 0 then
        print("".. SNOWBALL.prefix .."There was a problem checking the position of the waiting room, please check the conditions.")
        return false
    end

    if getTileThingByPos(SNOWBALL.tpEnterEventPos).itemid == 0 then
        print("".. SNOWBALL.prefix .."There was a problem when checking the existence of the position to create the event teleport, please check the conditions.")
        return false
    end
    return true
end

function throwSnowball(cid, pos, rounds, dir)
    local player = Player(cid)
    
    if rounds == 0 then
        return true
    end
    
    if player then
        local dirConfig = SNOWBALL.directions[dir]
        if dirConfig then
            local newPos = Position(pos.x + dirConfig.dirPos.x, pos.y + dirConfig.dirPos.y, pos.z)
            if isWalkable(newPos) then
                if Tile(newPos):getTopCreature() then
                    local target = Tile(newPos):getTopCreature()
                    if Player(target:getId()) then
                        if SNOWBALL.frozenBodies[target:getSex()] then
                            local frozenCorpse = SNOWBALL.frozenBodies[target:getSex()][target:getDirection()][math.random(1, #SNOWBALL.frozenBodies[target:getSex()][target:getDirection()])]
                            Game.createItem(frozenCorpse, 1, target:getPosition())
                            local item = Item(getTileItemById(target:getPosition(), frozenCorpse).uid)
                            addEvent(function() item:remove(1) end, 3000)
                        end
                    target:getPosition():sendMagicEffect(3)
                    target:teleportTo(CACHE_AREA_POSITIONS[math.random(1, #CACHE_AREA_POSITIONS)])
                    target:getPosition():sendMagicEffect(50)
                    target:setStorageValue(10109, (target:getStorageValue(10109) - SNOWBALL.lossPoints))
                    target:setStorageValue(10108, SNOWBALL.ammoDeath)
                    target:sendTextMessage(29, (SNOWBALL.messageHit):format(player:getName(), SNOWBALL.lossPoints, target:getStorageValue(10109)))
                    player:setStorageValue(10109, player:getStorageValue(10109) + SNOWBALL.hitPoints)
                    player:sendTextMessage(29, (SNOWBALL.messageHitOpponent):format(target:getName(), SNOWBALL.hitPoints, player:getStorageValue(10109)))
                    
                    if(CACHE_PLAYERS[2] == player:getId()) and player:getStorageValue(10109) >= Player(CACHE_PLAYERS[1]):getStorageValue(10109) then
                        player:getPosition():sendMagicEffect(7)
                        player:sendTextMessage(29, SNOWBALL.messageLeader)
                        Player(CACHE_PLAYERS[1]):getPosition():sendMagicEffect(16)
                        Player(CACHE_PLAYERS[1]):sendTextMessage(29, SNOWBALL.messageLostLeader)
                    end
                    
                    table.sort(CACHE_PLAYERS, function(a, b) return Player(a):getStorageValue(10109) > Player(b):getStorageValue(10109) end)
                else
                    newPos:sendMagicEffect(3)
                end
                return true
            end
                pos:sendDistanceEffect(newPos, 13)
                pos = newPos
                return addEvent(throwSnowball, SNOWBALL.ammoSpeed, player:getId(), pos, rounds - 1, dir)
            end
            newPos:sendMagicEffect(3)
            return true
        end
    end
    return true
end

function endEvent()
    local str = "       ## -> SnowBall Ranking <- ##\n\n"

    for rank, players in ipairs(CACHE_PLAYERS) do
        		if rank == 1 then
			Player(players):addEventPoints("boss", 100)
			Player(players):addEventPoints("task", 100)
		elseif rank == 2 then
			Player(players):addEventPoints("boss", 50)
			Player(players):addEventPoints("task", 50)
		elseif rank == 3 then
			Player(players):addEventPoints("boss", 30)
			Player(players):addEventPoints("task", 30)
		end

        str = str .. rank .. ". " .. Player(players):getName() .. ": " .. Player(players):getStorageValue(10109) .. " point(s)\n"
        Player(players):teleportTo(Player(players):getTown():getTemplePosition())
    end

    for _, cid in ipairs(CACHE_PLAYERS) do
        Player(cid):showTextDialog(2111, str)
    end

    broadcastMessage(SNOWBALL.prefix .. SNOWBALL.messageEventEnded)
    return true
end

function isWalkable(pos)
    for i = 0, 255 do
        pos.stackpos = i

        local item = Item(getTileThingByPos(pos).uid)
        if item ~= nil then
            if item:hasProperty(2) or item:hasProperty(3) or item:hasProperty(7) then
                return false
            end
        end
    end
    return true
end

function isInArena(player)
    local pos = player:getPosition()

    if pos.z == SNOWBALL.arenaPos[1].z then
        if pos.x >= SNOWBALL.arenaPos[1].x and pos.y >= SNOWBALL.arenaPos[1].y then
            if pos.x <= SNOWBALL.arenaPos[2].x and pos.y <= SNOWBALL.arenaPos[2].y then
                return true
            end
        end
    end
    return false
end
