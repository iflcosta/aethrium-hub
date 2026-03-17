local table = {
    [50] = {type = "bank", id = {5000, 0}, msg = "5000 gold coins have been deposited into your bank for reaching level 50!"},
    [100] = {type = "bank", id = {20000, 0}, msg = "20000 gold coins have been deposited into your bank for reaching level 100!"},
    [200] = {type = "bank", id = {100000, 0}, msg = "100000 gold coins have been deposited into your bank for reaching level 200!"},
    [400] = {type = "addon", id = {154, 158}, msg = "You have received the Shaman Full addon for reaching level 400!"},
}

local storage = 15000

function onAdvance(player, skill, oldLevel, newLevel)
    if skill ~= SKILL_LEVEL or newLevel <= oldLevel then
        return true
    end

    for level, _ in pairs(table) do
        if newLevel >= level and player:getStorageValue(storage) < level then
            if table[level].type == "item" then
                player:addItem(table[level].id[1], table[level].id[2])
            elseif table[level].type == "bank" then
                player:setBankBalance(player:getBankBalance() + table[level].id[1])
            elseif table[level].type == "addon" then
                player:addOutfitAddon(table[level].id[1], 3)
                player:addOutfitAddon(table[level].id[2], 3)
            else
                return false
            end

            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, table[level].msg)
            player:setStorageValue(storage, level)
        end
    end

    player:save()

    return true
end
