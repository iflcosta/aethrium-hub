local talk = TalkAction("!fly")

local config = {
    places = {
        ["temple"] = Position(991, 1210, 7),
        ["depot"] = Position(961, 1211, 7),
    },
    onlyPz = true,
    storage = {
        active = true,
        storage = 89154,
        time = 5, -- in seconds
    },
}

function talk.onSay(player, words, param)
    if not param or param == "" then
        local message = "You can go to the following places:\n\n"
        local locations = ""
        for place, _ in pairs(config.places) do
            locations = locations .. place .. "\n"
        end
        message = message .. locations
        player:popupFYI(message)
        return false
    end

    if config.storage.active and player:getStorageValue(config.storage.storage) > os.time() then
        player:sendCancelMessage("You need to wait " .. string.diff(player:getStorageValue(config.storage.storage) - os.time(), true) .. " to use this command again.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    param = param:lower():trim()
    local destination = config.places[param]

    if not destination then
        player:sendCancelMessage("Location not found.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if config.onlyPz and not Tile(player:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE) then
        player:sendCancelMessage("You need to be in a protection zone to use this command.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    player:getPosition():sendMagicEffect(CONST_ME_POFF)
    player:teleportTo(destination)
    player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
    player:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, "You have teleported to {" .. param .. "}.")

    if config.storage.active then
        player:setStorageValue(config.storage.storage, os.time() + config.storage.time)
    end

    return false
end

talk:separator(" ")
talk:register()
