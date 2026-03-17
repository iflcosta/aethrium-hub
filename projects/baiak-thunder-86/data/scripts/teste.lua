local config = {
    duration = 6 * 60 * 60, -- 6 hours in seconds
    storageKey = 1000,  -- Representative number for storage
    talkactionCommand = "/chestevent",
    eventMessageStart = "Chest Event activated for 6 hours.",
    eventMessageStop = "Chest Event deactivated.",
    eventBosses = {
        {
            names = {"Rotworm", "Rotworm Boss", "Rotworm Skeleton"},
            levelRanges = { min = 0, max = 2000 },
           fromPos = Position(952, 1196, 8), -- Posição inicial da área do evento do chefe
            toPos = Position(1023, 1222, 8), -- Posição final da área do evento do chefe
            dropChances = {
                { itemId = 2161, chance = 1.0, count = 3 }, -- 100% chance, 3 items
                { itemId = 2160, chance = 1.0, count = 2 }  -- 100% chance, 2 items
            }
        },
        {
            names = {"Demon"},
            levelRanges = { min = 51, max = 100 },
            fromPos = Position(300, 300, 7),
            toPos = Position(400, 400, 7),
            dropChances = {
                { itemId = 9876, chance = 0.05, count = 1 }, -- 5% chance, 1 item
                { itemId = 5432, chance = 0.95, count = 2 }  -- 95% chance, 2 items
            }
        },
        {
            names = {"Rat"},
            levelRanges = { min = 101, max = 150 },
            fromPos = Position(500, 500, 7),
            toPos = Position(600, 600, 7),
            dropChances = {
                { itemId = 1111, chance = 0.5, count = 1 }, -- 50% chance, 1 item
                { itemId = 2222, chance = 0.5, count = 1 }  -- 50% chance, 1 item
            }
        },
        -- Add other boss configurations as needed
    },
}

local monsters = {}  -- Adicione esta linha para definir a variável monsters


local function isPositionInRange(position, fromPos, toPos)
    return position.x >= fromPos.x and position.x <= toPos.x
       and position.y >= fromPos.y and position.y <= toPos.y
       and position.z == fromPos.z
end

local function isPlayerInEvent(player, bossName)
    local playerLevel = player:getLevel()
    local playerPos = player:getPosition()
    local eventEndTime = Game.getStorageValue(config.storageKey) or 0

    for _, boss in ipairs(config.eventBosses) do
        for _, name in ipairs(boss.names) do
            if name:lower() == bossName:lower() then
                if os.time() <= eventEndTime and playerLevel >= boss.levelRanges.min and playerLevel <= boss.levelRanges.max then
                    return isPositionInRange(playerPos, boss.fromPos, boss.toPos)
                end
            end
        end
    end

    return false
end

local creatureevent = CreatureEvent("BossKill")

function creatureevent.onKill(creature, target)
    if not target or not target:isCreature() then
        return true
    end

    local targetMonster = Monster(target:getId())
    if not targetMonster then
        return true
    end

    local player = creature:getPlayer()
    if not player then
        return true
    end

    local monsterName = targetMonster:getName()
    local boss = monsters[monsterName:lower()]

    if not boss or not isPlayerInEvent(player, monsterName) then
        return true
    end

    local dropIndex = math.random(1, #boss.dropChances)
    local chosenDrop = boss.dropChances[dropIndex]
    local dropChance = math.random()

    -- Verificar se o item deve ser dropado com base na chance de drop
    if dropChance <= chosenDrop.chance then
        local itemCount = chosenDrop.count or 1
        local backpack = player:addItem(config.rewardBag, false)
        local isStackable = ItemType(chosenDrop.itemId):isStackable()

        -- Adicionar o item ao inventário do jogador, lidando com itens empilháveis e não empilháveis
        if isStackable then
            local fullStacks = math.floor(itemCount / 100)
            local remainder = itemCount % 100

            for i = 1, fullStacks do
                backpack:addItem(chosenDrop.itemId, 100)
            end

            if remainder > 0 then
                backpack:addItem(chosenDrop.itemId, remainder)
            end
        else
            backpack:addItem(chosenDrop.itemId, itemCount)
        end

        -- Enviar efeitos visuais e mensagens para o jogador
        targetMonster:getPosition():sendMagicEffect(326)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Saco de recompensa adicionado ao seu inventário: " .. ItemType(config.rewardBag):getName() .. ", " .. ItemType(chosenDrop.itemId):getName() .. " (" .. itemCount .. "x)")

        -- Adicionar prints para verificar o storage e as posições
        print("Chave de Storage Ativada:", boss.storageKey)
        print("Posição de Início da Arena:", boss.fromPos)
        print("Posição Final da Arena:", boss.toPos)
    end

    return true
end

-- Registrar o evento de criatura
creatureevent:register()

local creatureevent2 = CreatureEvent("registerlogin")

function creatureevent2.onLogin(player)
    player:registerEvent("BossKill")
    return true
end

creatureevent2:register()

local talkaction = TalkAction(config.talkactionCommand)

function talkaction.onSay(player, words, param, type)
    if not player:getGroup():getAccess() then
        return true
    end

    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end

    local storedTime = Game.getStorageValue(config.storageKey)
    if storedTime == nil then
        storedTime = 0
        Game.setStorageValue(config.storageKey, storedTime)
    end

    local eventActive = storedTime > os.time()

    if param == "start" then
        if eventActive then
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "Chest Event is already active.")
        else
            Game.setStorageValue(config.storageKey, os.time() + config.duration)
            Game.broadcastMessage(config.eventMessageStart)
        end
    elseif param == "stop" then
        if not eventActive then
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "Chest Event is not active.")
        else
            Game.setStorageValue(config.storageKey, 0)
            Game.broadcastMessage(config.eventMessageStop)
        end
    else
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Invalid parameter. Use '" .. config.talkactionCommand .. " start' or '" .. config.talkactionCommand .. " stop'.")
    end

    return false
end

talkaction:separator(" ")
talkaction:register()