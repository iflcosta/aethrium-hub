local talk = TalkAction("!mailbox")

function talk.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return false
    end

    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end

    local split = param:split(",")
    if #split < 3 then
        player:sendCancelMessage("Insufficient parameters. Usage: !mailbox [name], [id], [count]")
        return false
    end

    local name = split[1]
    local id = split[2]
    local count = split[3]

    if not tonumber(id) or not tonumber(count) then
        player:sendCancelMessage("Provide only numbers for ID and count.")
        return false
    end

    local targetPlayer = Player(name)
    if targetPlayer then
        sendMailbox(targetPlayer:getId(), tonumber(id), tonumber(count))
        player:sendCancelMessage("Sent ".. count .."x ".. ItemType(tonumber(id)):getName() .." to player ".. targetPlayer:getName())
        return false
    end

    local resultId = db.storeQuery("SELECT `id` FROM `players` WHERE `name` = " .. db.escapeString(name))
    if not resultId then
        return false
    end

    local targetPlayerGUID = result.getDataInt(resultId, "id")
    result.free(resultId)

    targetPlayer = Player(targetPlayerGUID, true) -- load from db
    if not targetPlayer then
        return false
    end

    local item = Game.createItem(tonumber(id), tonumber(count))
    targetPlayer:getInbox():addItemEx(item, INDEX_WHEREEVER, FLAG_NOLIMIT)
    player:sendCancelMessage("Sent ".. count .."x ".. ItemType(tonumber(id)):getName() .." to player ".. targetPlayer:getName())
    targetPlayer:delete()
    return false
end

talk:separator(" ")
talk:register()
