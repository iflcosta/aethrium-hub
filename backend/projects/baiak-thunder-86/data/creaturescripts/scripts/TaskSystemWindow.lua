local npcMissions = {
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    [1] = {name = "Rat Killer", -- Kill monsters only
        arrayName = {"Rat", "rat", "Rats", "rats", "Pest", "pest", "Pests", "pests", "rat killer", "Rat killer", "Rat Killer"},
        storageMission = 43000, -- Mission storage should be unique even in different NPC files.
        storageRequired = nil, -- Use this to require different tasks to be done complete before this task can be started.
        messageTaskInfo = "I need you to kill 10 rats and 10 cave rats.", -- This message is said to the player when he starts the task.
        messageTaskComplete = "Thank you! Those pests have ruined my store. unfortunately they will be back. The rats aren't the main {problem}", -- This message is said to the player when he finishs the task.
        windowMsg = "Kill rats in the basement.", -- This text is shown under the title of the modal window
        monsters = { -- Monster task
            [1] = {name = "Rat", amount = 10, storage = 41000}, -- Monster storages should be unique even in different NPC files.
            [2] = {name = "Cave Rat", amount = 10, storage = 41001}
        },
        --Rewards--
        exp = 1000, -- Exp given to the player for completing the task.
        rewardItems = { -- Items given to the player for completing the task.
            [1] = {itemid = 2390, amount = 1}
        },
        setStorage = nil -- Use this to set any storages you want to when the player completes the task excluding storageNpc and storageMission
    },
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    [2] = {name = "Troll Hunter",
        arrayName = {"troll hunter", "Troll Hunter", "Troll", "troll", "Trolls", "trolls"},
        storageMission = 43001,
        storageRequired = {43000},
        messageTaskInfo = "I need you to kill 20 trolls.",
        messageTaskComplete = "You are truley a legend. There is one more thing I need. Could you {help} me one more time?",
        windowMsg = "Kill trolls in the forst to the east. Also, collect x items",
        monsters = {
            [1] = {name = "Troll", amount = 20, storage = 41002},
        },
        collectItems = { -- Collect Items task
            [1] = {itemid = 1111, amount = 1}
        },
        --Rewards--
        exp = 5000,
        rewardItems = {
            [1] = {itemid = 2390, amount = 1}
        },
        setStorage = {
            [1] = {41532, 1}
        }
    },
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    [3] = {name = "The Collector", -- Collect Items only
        arrayName = {"collector", "Collector", "collect", "Collect", "cheese", "Cheese"},
        storageMission = 43003,
        storageRequired = {43001, 43002},
        messageTaskInfo = "I need you to collect 10 cheese.",
        messageTaskComplete = "You are truley a legend. I do not need anymore help.",
        windowMsg = "Collect x items",
        collectItems = { -- Collect Items task
            [1] = {itemid = 1111, amount = 1}
        },
        --Rewards--
        exp = 5000,
        rewardItems = {
            [1] = {itemid = 2390, amount = 1}
        },
        setStorage = nil
    }
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------
}

function onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId == 0x10 then
        if buttonId == 0x01 then
            local TASK = npcMissions[choiceId]
            
            if not TASK then print('Internal Error finding Task') return false end
            if player:getStorageValue(TASK.storageMission) == 2 then
                local window = ModalWindow(0x12, TASK.name, TASK.windowMsg)
                window:addChoice(0x00, "You have already completed this task.")
                window:addButton(0x00, "Exit")
                window:setDefaultEnterButton(0x00)
                window:sendToPlayer(player)
                return true
            elseif player:getStorageValue(TASK.storageMission) == 1 then
                local window = ModalWindow(0x12, TASK.name, TASK.windowMsg)
                local count = 1
                if TASK.monsters then
                    for i = 1, #TASK.monsters do
                        window:addChoice(count, "("..player:getStorageValue(TASK.monsters[i].storage).."/"..TASK.monsters[i].amount.." "..TASK.monsters[i].name..".")
                        count = count + 1
                    end
                end
                
                if TASK.collectItems then
                    for i = 1, #TASK.collectItems do
                        window:addChoice(count, "("..player:getItemCount(TASK.collectItems[i].itemid).."/"..TASK.collectItems[i].amount.." "..ItemType(TASK.collectItems[i].itemid):getName()..".")
                        count = count + 1
                    end
                end
                
                window:addButton(0x00, "Exit")
                window:addButton(choiceId, "Turn-In")
                window:setDefaultEnterButton(0x01)
                window:sendToPlayer(player)
                return true
                
            elseif player:getStorageValue(TASK.storageMission) == -1 then
                local window = ModalWindow(0x11, TASK.name, TASK.windowMsg)
                local count = 1
                if TASK.monsters then
                    for i = 1, #TASK.monsters do
                        window:addChoice(count, "Kill: "..TASK.monsters[i].amount.." "..TASK.monsters[i].name..".")
                        count = count + 1
                    end
                end
                
                if TASK.collectItems then
                    for i = 1, #TASK.collectItems do
                        window:addChoice(count, "Collect: "..TASK.collectItems[i].amount.." "..ItemType(TASK.collectItems[i].itemid):getName()..".")
                        count = count + 1
                    end
                end
                
                window:addButton(0x00, "Exit")
                window:addButton(choiceId, "Accept")
                window:setDefaultEnterButton(0x01)
                window:sendToPlayer(player)
                return true
            end
            return true
        end
    
    elseif modalWindowId == 0x11 then
            local TASK = npcMissions[buttonId]
        
            if not TASK then print('Internal Error finding Task') return false end
        
            player:setStorageValue(TASK.storageMission, 1)
        
            if TASK.monsters then
                for i = 1, #TASK.monsters do
                    player:setStorageValue(TASK.monsters[i].storage, 0)
                end
            end
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You have started: "..TASK.name.."!")
            return true
            
    elseif modalWindowId == 0x12 then
            local TASK = npcMissions[buttonId]
            
            if not TASK then print('Internal Error finding Task') return false end
            
            local canTurnIn = true
            
            if TASK.monsters then
                for i = 1, #TASK.monsters do
                    if player:getStorageValue(TASK.monsters[i].storage) < TASK.monsters[i].amount then
                        canTurnIn = false
                    end
                end
            end
            
            if TASK.collectItems then
                for i = 1, #TASK.collectItems do
                    if player:getItemCount(TASK.collectItems[i].itemid) < TASK.collectItems[i].amount then
                        canTurnIn = false
                    end
                end
            end
            
            if canTurnIn then
                if TASK.monsters then
                    for i = 1, #TASK.monsters do
                        player:setStorageValue(TASK.monsters[i].storage, -1)
                    end
                end
            
                if TASK.collectItems then
                    for i = 1, #TASK.collectItems do
                        player:removeItem(TASK.collectItems[i].itemid, TASK.collectItems[i].amount)
                    end
                end
                
                player:setStorageValue(TASK.storageMission, 2)
                
                if TASK.exp then
                    player:addExperience(TASK.exp)
                end
                
                if TASK.rewardItems then
                    for i = 1, #TASK.rewardItems do
                        player:addItem(TASK.rewardItems[i].itemid, TASK.rewardItems[i].amount, true)
                    end
                end
                
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You have completed: "..TASK.name.."!")
            else
                player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "You are not ready to turn in this task.")
            end
        end
    return true
end