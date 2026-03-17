function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    local amount = tonumber(param)
    if not amount or amount <= 0 then
        player:sendCancelMessage("Uso correto: /addtaskpoints <quantidade>")
        return false
    end

    local currentPoints = math.max(0, player:getStorageValue(20021))
    player:setStorageValue(20021, currentPoints + amount)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voce recebeu " .. amount .. " Task Points (Total: " .. (currentPoints + amount) .. ").")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    return false
end
