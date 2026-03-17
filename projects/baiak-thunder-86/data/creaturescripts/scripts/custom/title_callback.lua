-- ============================================================
-- TITLES SYSTEM - Modal Callback
-- ============================================================

local function titleCallback(player, button, choice, choiceId)

    
    if button.id ~= 1 then -- Not "Select"
        return
    end

    -- If the helper didn't resolve the choice object, use the choiceId directly
    local finalChoiceId = choiceId
    if choice and choice.id then
        finalChoiceId = choice.id
    end

    if not finalChoiceId then
        return
    end



    -- choiceId 0 = [None] - Clear Title
    if finalChoiceId == 0 then
        local success = player:setSelectedTitle(0)
        if success then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Title selected: [None]")
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            player:syncTitle() -- Sync visually
        else
            player:sendCancelMessage("Failed to clear title.")
        end
        return
    end

    -- Resolution of sequential index to actual title ID
    local count = player:getStorageValue(49099)
    if finalChoiceId > count then
        return
    end

    local titleId = player:getStorageValue(49099 + finalChoiceId)
    if player:setSelectedTitle(titleId) then
        local title = TitleConfig.titles[titleId]
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Title selected: [" .. title.name .. "]")
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
        player:syncTitle() -- Sync visually immediately
    else
        player:sendCancelMessage("You cannot select this title.")
    end
end

-- Register the callback in the helper system
if not modalWindows then
    modalWindows = { windows = {} }
end

table.insert(modalWindows.windows, {
    id = 4900,
    players = {}, -- This will be populated by the system or script if needed
    choices = {}, -- Not strictly needed if using sequential IDs
    buttons = {
        {id = 1, callback = titleCallback},
        {id = 2, callback = nil}
    }
})
