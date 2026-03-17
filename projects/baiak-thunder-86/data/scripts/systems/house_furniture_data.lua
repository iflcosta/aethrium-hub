-- House Furniture Configuration
-- This is just the data, loaded by other scripts

HouseFurniture = {
    -- Item IDs (furniture reais)
    DEPOT = 2589,
    WOODEN_CABINET = 37831,
    RUNE_STATUE_1 = 26075,
    RUNE_STATUE_2 = 26076,
    STONE_SHELF = 16098,
    STONE_SHELF_2 = 16097,
    -- BAMBOO_DRAWER = 3832, (REMOVIDO)
    OFFLINE_TRAIN_BOOST = 24682,  -- Offline training with 20% boost
    
    -- Nomes
    names = {
        [2589] = "Depot Box",
        [37831] = "Wooden Cabinet",
        [26075] = "Supply Statue",
        [26076] = "Supply Statue",
        [16098] = "Food Maker",
        [16097] = "Food Maker",
        [24682] = "Training Statue (20% Boost)",
    },
    
    -- Descrições
    descriptions = {
        [2589] = "Armazenamento pessoal (depot)",
        [37831] = "Compra potions e runas (20% barato)",
        [26075] = "Compra potions e runas (20% barato)",
        [26076] = "Compra potions e runas (20% barato)",
        [16098] = "Cria comida (-500 gp)",
        [16097] = "Cria comida (-500 gp)",
        [24682] = "Ativa treino offline com 20% BONUS",
    },
    
    -- Limites por casa
    limits = {
        [2589] = 1,
        [37831] = 2,
        [26075] = 2,
        [26076] = 2,
        [16098] = 1,
        [16097] = 1,
        [24682] = 1,
    },
    
    -- Preços mensais por VIP tier
    prices = {
        individual = {
            [0] = 5,  -- FREE
            [2] = 4,  -- SILVER
            [3] = 3,  -- GOLD
        }
    },
    
    -- Storages
    ST_TRIAL_USED = 95001,
    ST_OFFLINE_TRAINER = 95003,
    
    -- Configurações
    TRIAL_DAYS = 7,
    SUBSCRIPTION_DAYS = 30,
}

-- Funções auxiliares
function getVipTier(player)
    local vip = player:getStorageValue(50200)
    if vip >= 3 then return 3 end
    if vip >= 2 then return 2 end
    return 0
end

function getIndividualPrice(player)
    return HouseFurniture.prices.individual[getVipTier(player)]
end

function hasPoints(player, amount)
    return player:getPremiumPoints() >= amount
end

function removePoints(player, amount)
    if not hasPoints(player, amount) then return false end
    player:setPremiumPoints(player:getPremiumPoints() - amount)
    return true
end

function isHouseOwner(player, houseId)
    local house = House(houseId)
    return house and house:getOwnerGuid() == player:getGuid()
end

function countActiveFurniture(houseId, itemId)
    local query = db.storeQuery(string.format(
        "SELECT COUNT(*) as c FROM house_furniture WHERE house_id = %d AND item_id = %d AND expires_at > %d",
        houseId, itemId, os.time()))
    
    if not query then return 0 end
    local count = result.getNumber(query, "c")
    result.free(query)
    return count
end

function hasUsedTrial(player)
    return player:getStorageValue(HouseFurniture.ST_TRIAL_USED) > 0
end

function markTrialUsed(player)
    player:setStorageValue(HouseFurniture.ST_TRIAL_USED, 1)
end
