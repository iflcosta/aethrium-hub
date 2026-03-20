-- ============================================
-- BAIAK THUNDER - TASK SYSTEM CREATURESCRIPT
-- Tracks kills for both Normal and Daily Tasks
-- ============================================

local taskSystemEvent = CreatureEvent("taskSystem")

function taskSystemEvent.onKill(creature, target)
    if not creature:isPlayer() or not target:isMonster() then
        return true
    end
    
    local targetName = target:getName():lower()
    local player = creature
    
    -- ============================================
    -- NORMAL TASK CHECK
    -- ============================================
    local taskId = player:getStorageValue(task_storage)
    if taskId > 0 then
        local task = task_monsters[taskId]
        if task then
            local currentKills = math.max(0, player:getStorageValue(task_kills))
            if currentKills < task.amount then
                -- Check if the killed monster is in the task's monster list
                local isValidMonster = false
                for _, monsterName in ipairs(task.mons_list) do
                    if monsterName:lower() == targetName then
                        isValidMonster = true
                        break
                    end
                end
                
                if isValidMonster then
                    player:setStorageValue(task_kills, currentKills + 1)
                    local newKills = currentKills + 1
                    
                    -- Send progress message
                    local msgEnabled = player:getStorageValue(176608)
                    if msgEnabled <= 0 then
                        player:say("[Task] " .. targetName:gsub("^%l", string.upper) .. ": " .. newKills .. "/" .. task.amount, TALKTYPE_MONSTER_SAY)
                    end
                    
                    -- Task completed
                    if newKills >= task.amount then
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[Task System] Congratulations! You completed the task: " .. task.name .. "! Return to the NPC to claim your reward.")
                    end
                end
            end
        end
    end
    
    -- ============================================
    -- DAILY TASK CHECK
    -- ============================================
    local dailyId = player:getStorageValue(taskd_storage)
    if dailyId > 0 then
        local dailyTask = task_daily[dailyId]
        if dailyTask then
            local currentKills = math.max(0, player:getStorageValue(taskd_kills))
            if currentKills < dailyTask.amount then
                -- Check if the killed monster is in the daily task's monster list
                local isValidMonster = false
                for _, monsterName in ipairs(dailyTask.mons_list) do
                    if monsterName:lower() == targetName then
                        isValidMonster = true
                        break
                    end
                end
                
                if isValidMonster then
                    player:setStorageValue(taskd_kills, currentKills + 1)
                    local newKills = currentKills + 1
                    
                    -- Send progress message
                    local msgEnabled = player:getStorageValue(176608)
                    if msgEnabled <= 0 then
                        player:say("[Daily Task] " .. targetName:gsub("^%l", string.upper) .. ": " .. newKills .. "/" .. dailyTask.amount, TALKTYPE_MONSTER_SAY)
                    end
                    
                    -- Daily task completed
                    if newKills >= dailyTask.amount then
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[Daily Task] Congratulations! You completed the daily task: " .. dailyTask.name .. "! Return to the NPC to claim your reward.")
                    end
                end
            end
        end
    end
    
    return true
end

taskSystemEvent:register()

-- ============================================
-- LOGIN EVENT - Register task event
-- ============================================

local creatureEvent = CreatureEvent("taskLogin")

function creatureEvent.onLogin(player)
    player:registerEvent("taskSystem")
    return true
end

creatureEvent:register()

-- ============================================
-- TALK ACTION - !task command
-- ============================================

local talkAction = TalkAction("!task", "/task")

function talkAction.onSay(player, words, param)
    param = param:lower()
    
    -- Toggle kill counter messages
    if isInArray({"counter", "contador"}, param) then
        player:setStorageValue(176608, player:getStorageValue(176608) <= 0 and 1 or 0)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Task System] Counter messages " .. (player:getStorageValue(176608) <= 0 and "enabled" or "disabled") .. ".")
        return true
    end
    
    local message = "=== ACTIVE TASKS PROGRESS ===\n\n"
    
    -- Show Normal Task info
    local taskId = player:getStorageValue(task_storage)
    if taskId > 0 and task_monsters[taskId] then
        local task = task_monsters[taskId]
        local currentKills = math.max(0, player:getStorageValue(task_kills))
        message = message .. "[ELITE TASK]\n"
        message = message .. " Task: " .. task.name .. "\n"
        message = message .. " Progress: [" .. currentKills .. "/" .. task.amount .. "]\n"
        message = message .. " Monsters: " .. table.concat(task.mons_list, ", ") .. "\n"
        message = message .. " Experience: " .. task.exp .. "\n"
        message = message .. " Points: " .. task.pointsTask[1] .. "\n\n"
    else
        message = message .. "[ELITE TASK]\n"
        message = message .. " No active elite task.\n\n"
    end
    
    -- Show Daily Task info
    local dailyId = player:getStorageValue(taskd_storage)
    if dailyId > 0 and task_daily[dailyId] then
        local dailyTask = task_daily[dailyId]
        local currentKills = math.max(0, player:getStorageValue(taskd_kills))
        message = message .. "[DAILY TASK]\n"
        message = message .. " Task: " .. dailyTask.name .. "\n"
        message = message .. " Progress: [" .. currentKills .. "/" .. dailyTask.amount .. "]\n"
        message = message .. " Monsters: " .. table.concat(dailyTask.mons_list, ", ") .. "\n"
        message = message .. " Experience: " .. dailyTask.exp .. "\n"
        message = message .. " Points: " .. dailyTask.pointsTask[1] .. "\n"
    else
        message = message .. "[DAILY TASK]\n"
        message = message .. " No active daily task.\n"
    end
    
    local modal = ModalWindow(1005, "Task System", message)
    modal:addButton(1, "Close")
    modal:setDefaultEnterButton(1)
    modal:setDefaultEscapeButton(1)
    modal:sendToPlayer(player)
    
    return true
end

talkAction:separator(" ")
talkAction:register()

-- ============================================
-- PLAYER LOOK - Show Title (Task Rank removido - use !taskrank)
-- Title display moved to data/scripts/eventcallbacks/player/default_onLook.lua
