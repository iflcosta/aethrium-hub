-- House Furniture - Complete System with Training
dofile('data/scripts/systems/house_furniture_data.lua')

-- Food prices
local FOOD_PRICE = 500  -- 500gp per food

-- Offline Training Boost Furniture ID (new item)
local OFFLINE_TRAIN_BOOST_ITEM = 24682  -- Custom item for offline training boost

-- Potion/Rune prices (20% cheaper than shop)
local POTIONS = {
    {id = 7618, name = "Health Potion", price = 40},      -- shop 50
    {id = 7620, name = "Mana Potion", price = 40},         -- shop 50
    {id = 7588, name = "Strong Health", price = 80},       -- shop 100
    {id = 7589, name = "Strong Mana", price = 80},         -- shop 100
    {id = 7591, name = "Great Health", price = 120},       -- shop 150
    {id = 7590, name = "Great Mana", price = 120},         -- shop 150
    {id = 7643, name = "Ultimate Health", price = 200},    -- shop 250
}

local RUNES = {
    {id = 2265, name = "Light Magic Missile", price = 12},   -- shop 15
    {id = 2266, name = "Heavy Magic Missile", price = 24},  -- shop 30
    {id = 2273, name = "Stalagmite", price = 20},           -- shop 25
    {id = 2281, name = "Fireball", price = 60},             -- shop 75
    {id = 2305, name = "Explosion", price = 52},           -- shop 65
    {id = 2313, name = "Energy Field", price = 40},        -- shop 50
    {id = 2268, name = "Cure Poison", price = 30},          -- shop 38
}

-- Trainer dummies for online training (exercise weapons with bonus)
local TRAINERS = {
    {id = 31219, name = "Monk Trainer", skill = "Melee", bonus = 10, price = 5000},   -- 10% bonus
    {id = 31217, name = "Demon Trainer", skill = "Melee", bonus = 20, price = 10000},  -- 20% bonus
    {id = 31215, name = "Ferumbras Trainer", skill = "Melee", bonus = 30, price = 20000}, -- 30% bonus
}

-- Storage for offline training boost
local OFF_TRAIN_BOOST_STORAGE = 54010
local OFF_TRAIN_TIME_STORAGE = 54001
local OFF_TRAIN_SKILL_STORAGE = 54002

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local tile = player:getTile()
    local house = tile and tile:getHouse()
    
    if not house then
        player:sendCancelMessage("You must be inside a house to use this furniture.")
        return true
    end

    local itemId = item:getId()
    
    -- FOOD OVEN (16098 / 16097) - Cria food por 50k (100 fire mushrooms)
    if itemId == HouseFurniture.STONE_SHELF or itemId == HouseFurniture.STONE_SHELF_2 then
        local BATCH_PRICE = 50000
        if player:getMoney() >= BATCH_PRICE then
            player:removeMoney(BATCH_PRICE)
            player:addItem(2795, 100)  -- 100 fire mushrooms
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Food created! 100x Fire Mushrooms (-" .. BATCH_PRICE .. " gp)")
        else
            player:sendCancelMessage("Voce precisa de " .. BATCH_PRICE .. " gp!")
        end
        return true
    end
    
    -- OFFLINE TRAINING BOOST (18492) - Furniture para treino offline com 20% boost
    if itemId == OFFLINE_TRAIN_BOOST_ITEM then
        -- Verificar se tem tempo de treino disponível
        local trainTime = player:getStorageValue(OFF_TRAIN_TIME_STORAGE)
        if trainTime < 0 then trainTime = 0 end
        
        if trainTime < 60 then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce precisa de pelo menos 60 segundos de treino offline disponivel.")
            return true
        end
        
        -- Ativar treino offline com 20% boost
        player:setStorageValue(OFF_TRAIN_BOOST_STORAGE, 20)  -- 20% boost
        
        -- Criar modal para escolher skill
        local modal = ModalWindow(5400, "Escolha o Skill", "Voce iniciou treino offline com 20% BONUS! Qual skill deseja treinar?")
        
        modal:addButton(1, "Club")
        modal:addButton(2, "Sword")
        modal:addButton(3, "Axe")
        modal:addButton(4, "Distance")
        modal:addButton(5, "Magic")
        modal:addButton(99, "Cancelar")
        
        -- Armazenar o item uid para uso posterior
        player:setStorageValue(54010, item:getUniqueId())
        
        modal:sendToPlayer(player)
        return true
    end
    
    
    -- RUNE STATUES - Potions e Runes
    if itemId == HouseFurniture.RUNE_STATUE_1 or itemId == HouseFurniture.RUNE_STATUE_2 then
        local potions = {
            {id = 7618, price = 40, currency = "GP"},   -- Health Potion
            {id = 7620, price = 40, currency = "GP"},   -- Mana Potion
            {id = 7588, price = 80, currency = "GP"},   -- Strong Health
            {id = 7589, price = 80, currency = "GP"},   -- Strong Mana
            {id = 7591, price = 120, currency = "GP"},  -- Great Health
            {id = 7590, price = 120, currency = "GP"},  -- Great Mana
            {id = 8473, price = 250, currency = "GP"},  -- Ultimate Health (CORRIGIDO: 8473)
        }

        local runes = {
            {id = 2268, price = 150, currency = "GP"},  -- Sudden Death (Adicionado)
            {id = 2313, price = 52, currency = "GP"},   -- Explosion (CORRIGIDO: 2313)
            {id = 2304, price = 60, currency = "GP"},   -- Great Fireball (CORRIGIDO: 2304)
            {id = 2311, price = 24, currency = "GP"},   -- Heavy Magic Missile (CORRIGIDO: 2311)
            {id = 2287, price = 12, currency = "GP"},   -- Light Magic Missile (CORRIGIDO: 2287)
            {id = 2265, price = 40, currency = "GP"},   -- Intense Healing (CORRIGIDO: 2265)
            {id = 2292, price = 20, currency = "GP"},   -- Stalagmite
        }

        local function encodeDynamic(items)
            local parts = {}
            for _, item in ipairs(items) do
                local it = ItemType(item.id)
                local name = it and it:getName() or "Unknown Item"
                local clientId = item.id
                if it then
                    clientId = it:getClientId()
                end
                table.insert(parts, string.format('{"id":%d,"name":"%s","price":%d,"currency":"%s"}', clientId, name, item.price, item.currency))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        end

        local jsonBuffer = string.format('{"potions":%s,"runes":%s}', 
            encodeDynamic(potions), encodeDynamic(runes))
        
        player:sendExtendedOpcode(153, jsonBuffer)
        return true
    end
    
    return true
end
