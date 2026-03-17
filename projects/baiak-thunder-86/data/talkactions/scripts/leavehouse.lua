-- ============================================================
-- !leavehouse - Leave House + Refund Furniture (PP Items)
-- ============================================================

-- Furniture items purchased with Premium Points
-- Prices synchronized with furniture_client.lua
local FURNITURE_REFUND = {
    [16098] = {name = "Food Maker",              price = 10},
    [26075] = {name = "Supply Statue",          price = 15},
    [26076] = {name = "Rune Statue 2",         price = 15},
    [24682] = {name = "Training Statue",       price = 30},
    [31219] = {name = "Monk Trainer",          price = 50},
    [31217] = {name = "Demon Trainer",         price = 100},
    [31215] = {name = "Ferumbras Trainer",     price = 200},
    [37831] = {name = "Wooden Cabinet",        price = 15},
}

function onSay(player, words, param)
    local position = player:getPosition()
    local tile = Tile(position)
    local house = tile and tile:getHouse()
    if not house then
        player:sendCancelMessage("You are not inside a house.")
        position:sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if house:getOwnerGuid() ~= player:getGuid() then
        player:sendCancelMessage("You are not the owner of this house.")
        position:sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- ============================================================
    -- REFUND: Scan all house tiles for furniture items
    -- ============================================================
    local totalRefund = 0
    local refundedItems = {}

    local houseTiles = house:getTiles()
    if houseTiles then
        for _, htile in ipairs(houseTiles) do
            local items = htile:getItems()
            if items then
                for i = #items, 1, -1 do
                    local item = items[i]
                    local itemId = item:getId()
                    local refundData = FURNITURE_REFUND[itemId]
                    if refundData then
                        local count = item:getCount() or 1
                        local refundAmount = refundData.price * count
                        totalRefund = totalRefund + refundAmount

                        if refundedItems[itemId] then
                            refundedItems[itemId].count = refundedItems[itemId].count + count
                            refundedItems[itemId].total = refundedItems[itemId].total + refundAmount
                        else
                            refundedItems[itemId] = {
                                name = refundData.name,
                                count = count,
                                total = refundAmount
                            }
                        end

                        item:remove()
                    end
                end
            end
        end
    end

    -- Credit the Premium Points
    if totalRefund > 0 then
        player:addPremiumPoints(totalRefund)

        local summary = "[House Refund] You received " .. totalRefund .. " PP back:\n"
        for _, data in pairs(refundedItems) do
            summary = summary .. "  - " .. data.name .. " x" .. data.count .. " = " .. data.total .. " PP\n"
        end
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, summary)
    end

    -- ============================================================
    -- LEAVE: Remove ownership
    -- ============================================================
    house:setOwnerGuid(0)
    player:sendTextMessage(MESSAGE_INFO_DESCR, "You have successfully left your house.")
    position:sendMagicEffect(CONST_ME_POFF)
    return false
end
