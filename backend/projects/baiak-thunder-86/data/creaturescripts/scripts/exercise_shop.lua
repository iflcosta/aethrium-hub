function onModalWindow(player, modalId, buttonId, choiceId)
    if modalId ~= 1000 then
        return false
    end

    if buttonId ~= 1 then
        return true
    end

    local exerciseItems = {
        [1] = {name = "exercise sword", id = 31208, price = 2000, charges = 500},
        [2] = {name = "durable exercise sword", id = 37935, price = 8000, charges = 1800},
        [3] = {name = "lasting exercise sword", id = 37941, price = 50000, charges = 14400},

        [4] = {name = "exercise axe", id = 31209, price = 2000, charges = 500},
        [5] = {name = "durable exercise axe", id = 37936, price = 8000, charges = 1800},
        [6] = {name = "lasting exercise axe", id = 37942, price = 50000, charges = 14400},

        [7] = {name = "exercise club", id = 31210, price = 2000, charges = 500},
        [8] = {name = "durable exercise club", id = 37937, price = 8000, charges = 1800},
        [9] = {name = "lasting exercise club", id = 37943, price = 50000, charges = 14400},

        [10] = {name = "exercise bow", id = 31211, price = 2000, charges = 500},
        [11] = {name = "durable exercise bow", id = 37938, price = 8000, charges = 1800},
        [12] = {name = "lasting exercise bow", id = 37944, price = 50000, charges = 14400},

        [13] = {name = "exercise rod", id = 31212, price = 2000, charges = 500},
        [14] = {name = "durable exercise rod", id = 37939, price = 8000, charges = 1800},
        [15] = {name = "lasting exercise rod", id = 37945, price = 50000, charges = 14400},

        [16] = {name = "exercise wand", id = 31213, price = 2000, charges = 500},
        [17] = {name = "durable exercise wand", id = 37940, price = 8000, charges = 1800},
        [18] = {name = "lasting exercise wand", id = 37946, price = 50000, charges = 14400},
    }

    local item = exerciseItems[choiceId]
    if not item then
        return true
    end

    if not player:removeMoney(item.price) then
        player:sendCancelMessage("You do not have enough money.")
        return true
    end

    local it = player:addItem(item.id, 1)
    if it then
        it:setAttribute(ITEM_ATTRIBUTE_CHARGES, item.charges)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You bought a " .. item.name .. " with " .. item.charges .. " charges.")
    end
    return true
end
