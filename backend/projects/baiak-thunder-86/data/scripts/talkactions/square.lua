local square = TalkAction("!target")

squareGuild = {}

function repeatSquare(id, color)
    if not squareGuild[id] then
        return false
    end

    local squareId = Player(squareGuild[id].target)

    if not squareId then
        return false
    end

    local spectators = Game.getSpectators(squareId:getPosition(), true, true, 0, 7, 0, 7)
    for _, viewer in ipairs(spectators) do
        if viewer:getGuild() and viewer:getGuild():getId() == id then
            viewer:sendCreatureSquare(squareId, squareGuild[id].color)
        end
    end

    addEvent(repeatSquare, 500, id, color)
end

function square.onSay(player, words, param)

    if player:getStorageValue(984145) > os.time() then
        player:sendCancelMessage("You need to wait for the cooldown.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if not param then
        player:sendCancelMessage("You need to inform the player.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local target = Player(param)
    if not target then
        player:sendCancelMessage("That player does not exist or is not online.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local guild = player:getGuild()
    
    if not guild then
        player:sendCancelMessage("You need to be part of a guild to use this command.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if player:getGuildLevel() < 2 then
        player:sendCancelMessage("You need to be a leader or vice-leader to use this command.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if target:getGuild() and target:getGuild():getId() == guild:getId() then
        player:sendCancelMessage("You cannot target a player from the same guild.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    squareGuild[guild:getId()] = {target = param, color = 204}
    repeatSquare(guild:getId(), 204)
    player:setStorageValue(984145, os.time() + 10 * 60)
    player:sendCancelMessage("Player ".. target:getName() .. " has been highlighted until they log out.")
    target:sendCancelMessage("You have been highlighted by player ".. player:getName() .." from guild ".. guild:getName() ..".")
    target:getPosition():sendMagicEffect(7)

    return false
end

square:separator(" ")
square:register()
