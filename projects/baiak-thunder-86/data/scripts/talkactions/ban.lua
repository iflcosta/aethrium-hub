local ban = TalkAction("/ban")

function ban.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end

    local split = param:split(",")
    local name = split[1]
    local duration = split[2]
    local reason = split[3]
    
    if not name or not duration or not reason then
        player:popupFYI("--------- [Ban System] ---------\n\n/ban Name, Duration (in days), Reason\n\nExample:\n/ban Movie, 7, Flood")
        return false
    end

    if not tonumber(duration) then
        player:sendCancelMessage("Please write the duration in numbers.")
        return false
    end

    local accountId = getAccountNumberByPlayerName(name)
    if accountId == 0 then
        return false
    end

    local resultId = db.storeQuery("SELECT 1 FROM `account_bans` WHERE `account_id` = " .. accountId)
    if resultId ~= false then
        result.free(resultId)
        return false
    end

    local currentTime = os.time()
    local expirationTime = currentTime + (duration * 86400)

    db.query("INSERT INTO `account_bans` (`account_id`, `reason`, `banned_at`, `expires_at`, `banned_by`) VALUES (" ..
            accountId .. ", " .. db.escapeString(reason) .. ", " .. currentTime .. ", " .. expirationTime .. ", " .. player:getGuid() .. ")")

    -- Notify the player about the ban
    local target = Player(name)
    if target then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, target:getName() .. " has been banned.")
        target:remove()
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, name .. " has been banned.")
    end
end

ban:separator(" ")
ban:register()
