-- ============================================================
-- TITLES SYSTEM - Admin Tools
-- /addtitle Name, ID  ->  Unlocks + selects title on player
-- /remtitle Name, ID  ->  Removes title from player
-- ============================================================

function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end



    if not TitleConfig then
        player:sendCancelMessage("TitleConfig is not loaded. Check titles_config.lua.")
        return false
    end

    if param == "" then
        player:sendCancelMessage("Usage: " .. words .. " Name, TitleID (1-6)")
        return true
    end

    local t = {}
    if string.find(param, ",") then
        t = string.splitTrimmed(param, ",")

    else
        -- Split by space and assume ID is the last part
        local parts = string.splitTrimmed(param, " ")

        if #parts >= 2 then
            local idPart = parts[#parts]
            local namePart = ""
            for i = 1, #parts - 1 do
                namePart = namePart .. (i == 1 and "" or " ") .. parts[i]
            end
            t = {namePart, idPart}
        end
    end

    if #t < 2 then

        player:sendCancelMessage("Usage: " .. words .. " Name, TitleID (1-6)")
        return true
    end

    local targetName = t[1]
    local titleId = tonumber(t[2])


    if not titleId or not TitleConfig.titles[titleId] then
        player:sendCancelMessage("Invalid title ID (" .. tostring(t[2]) .. "). Available IDs: 1-6.")
        return true
    end

    local target = Player(targetName)
    if not target then
        player:sendCancelMessage("Player '" .. targetName .. "' is not online.")
        return true
    end

    if string.find(words, "add") then

        -- Unlock the title in SQL + set it as active
        if target:addTitle(titleId) then
            target:setSelectedTitle(titleId)
            target:syncTitle() -- Sync visually
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
                "[Title] Success! Added [" .. TitleConfig.titles[titleId].name .. "] to " .. target:getName())
        else
            player:sendCancelMessage("System error: Could not add title to database.")
        end
    else

        -- Remove the title from SQL + clear if it was selected
        if target:removeTitle(titleId) then
            if target:getSelectedTitle() == titleId then
                target:setSelectedTitle(0)
            end
            target:syncTitle() -- Sync visually
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
                "[Title] Success! Removed [" .. TitleConfig.titles[titleId].name .. "] from " .. target:getName())
        else
            player:sendCancelMessage("System error: Could not remove title from database.")
        end
    end

    return true
end
