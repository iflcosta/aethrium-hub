-- ============================================================
-- TITLES SYSTEM - Modal Selection (!title)
-- ============================================================

function onSay(player, words, param)
    local unlocked = player:getUnlockedTitles()

    if #unlocked == 0 then
        player:sendCancelMessage("You haven't unlocked any titles yet.")
        return false
    end

    local selectedId = player:getSelectedTitle()
    local titleText = "Select your title below:"
    if selectedId then
        titleText = "Current title: [" .. TitleConfig.titles[selectedId].name .. "]\nSelect a new one or clear:"
    end

    local window = ModalWindow(4900, "Title System", titleText)

    -- Build choices with sequential indices (0-based)
    -- Index 0 = Clear Title
    window:addChoice(0, "[None] - Clear Title")

    -- Index 1, 2, 3... = actual titles
    for i, tid in ipairs(unlocked) do
        local title = TitleConfig.titles[tid]
        if title then
            local displayName = title.name
            if tid == selectedId then
                displayName = displayName .. " (Selected)"
            end
            window:addChoice(i, displayName)
        end
    end

    -- Store the mapping so the callback can resolve indices to title IDs
    player:setStorageValue(49099, #unlocked)
    for i, tid in ipairs(unlocked) do
        player:setStorageValue(49099 + i, tid)
    end

    window:addButton(1, "Select")
    window:addButton(2, "Cancel")

    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(2)

    -- Register event manually if not already registered (for real-time update without relog)
    player:registerEvent("ModalWindowHelper")

    -- Register player for the helper system
    if modalWindows and modalWindows.windows then
        for _, window in ipairs(modalWindows.windows) do
            if window.id == 4900 then
                window.players[player:getId()] = true
                break
            end
        end
    end

    window:sendToPlayer(player)
    return false
end
