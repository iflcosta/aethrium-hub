local time = 5 * 60 * 1000 -- 5 minutes in milliseconds

function onSay(player, words, param)
    if not player:getGuild() then
        player:sendCancelMessage("You do not belong to a guild.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if player:getStorageValue(98714) >= os.time() then
        player:sendCancelMessage("You need to wait for the cooldown to finish.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if player:getGuildLevel() == 1 then
        player:sendCancelMessage("You need to be a Vice Leader or Leader to change the guild outfit.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local guild = player:getGuild()
    local outfit = player:getOutfit()

    for _, member in ipairs(guild:getMembersOnline()) do
        local newOutfit = outfit
        if not member:hasOutfit(outfit.lookType, outfit.lookAddons) then
            local tmpOutfit = member:getOutfit()
            newOutfit.lookAddons = 0
            if not member:hasOutfit(outfit.lookType, 0) then
                newOutfit.lookType = tmpOutfit.lookType
            end
        end

        member:getPosition():sendMagicEffect(45)
        member:setOutfit(newOutfit)
        member:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, "Player {".. player:getName().. "} changed the guild outfit.")
    end

    player:getPosition():sendMagicEffect(CONST_ME_FIREAREA)
    player:setStorageValue(98714, os.time() + time)
    return true
end
