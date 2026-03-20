function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    local target = Player(param)
    if not target then
        target = player
    end
    
    for i = 50600, 50605 do
        target:setStorageValue(i, -1)
    end
    
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Task storages (50600-50605) have been reset for " .. target:getName() .. ".")
    return false
end
