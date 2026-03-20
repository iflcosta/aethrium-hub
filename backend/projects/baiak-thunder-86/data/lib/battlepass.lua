function addBattlepassXp(player, amount)
    local currentXp = math.max(0, player:getStorageValue(30050))
    player:setStorageValue(30050, currentXp + amount)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você recebeu +" .. amount .. " Aethrium Pass XP!")
end

BATTLEPASS_CONFIG = {
    pricing = {
        [0] = 300, -- Free (Sem VIP ou Storage 50200 <= 0)
        [1] = 250, -- VIP Prata (Storage 50200 == 1) - 17% OFF
        [2] = 200, -- VIP Prata (Storage 50200 == 1) - 33% OFF
        [3] = 150  -- VIP Ouro (Storage 50200 == 2) - 50% OFF
    },
    maxLevel = 50,
    storageXp = 30050,
    storageLevel = 92001,
    storagePremium = 92002,
    
    levels = {
        [1] = { requiredXP = 500, rewardFree = {gold = 50000, items = {{7620, 50}}}, rewardPremium = {gold = 100000, items = {{7620, 100}}} },
        [2] = { requiredXP = 1250, rewardFree = {gold = 12000}, rewardPremium = {gold = 30000} },
        [3] = { requiredXP = 2000, rewardFree = {gold = 12000}, rewardPremium = {gold = 30000} },
        [4] = { requiredXP = 2750, rewardFree = {gold = 12000}, rewardPremium = {gold = 30000} },
        [5] = { requiredXP = 3500, rewardFree = {taskPoints = 20}, rewardPremium = {taskPoints = 50, nexusCoins = 5} },
        [6] = { requiredXP = 4800, rewardFree = {gold = 20000}, rewardPremium = {gold = 50000} },
        [7] = { requiredXP = 6100, rewardFree = {gold = 20000}, rewardPremium = {gold = 50000} },
        [8] = { requiredXP = 7400, rewardFree = {gold = 20000}, rewardPremium = {gold = 50000} },
        [9] = { requiredXP = 8700, rewardFree = {gold = 20000}, rewardPremium = {gold = 50000} },
        [10] = { requiredXP = 10000, rewardFree = {gold = 200000, items = {{2160, 5}}}, rewardPremium = {gold = 500000, items = {{2160, 15}}} },
        [11] = { requiredXP = 12400, rewardFree = {gold = 30000}, rewardPremium = {gold = 75000} },
        [12] = { requiredXP = 14800, rewardFree = {gold = 30000}, rewardPremium = {gold = 75000} },
        [13] = { requiredXP = 17200, rewardFree = {gold = 30000}, rewardPremium = {gold = 75000} },
        [14] = { requiredXP = 19600, rewardFree = {gold = 30000}, rewardPremium = {gold = 75000} },
        [15] = { requiredXP = 22000, rewardFree = {taskPoints = 50}, rewardPremium = {items = {{8303, 1}}, nexusCoins = 10} },
        [16] = { requiredXP = 25600, rewardFree = {gold = 40000}, rewardPremium = {gold = 100000} },
        [17] = { requiredXP = 29200, rewardFree = {gold = 40000}, rewardPremium = {gold = 100000} },
        [18] = { requiredXP = 32800, rewardFree = {gold = 40000}, rewardPremium = {gold = 100000} },
        [19] = { requiredXP = 36400, rewardFree = {gold = 40000}, rewardPremium = {gold = 100000} },
        [20] = { requiredXP = 40000, rewardFree = {gold = 500000, items = {{2268, 100}}}, rewardPremium = {gold = 1000000, items = {{2268, 200}}} },
        [21] = { requiredXP = 45000, rewardFree = {gold = 50000}, rewardPremium = {gold = 125000} },
        [22] = { requiredXP = 50000, rewardFree = {gold = 50000}, rewardPremium = {gold = 125000} },
        [23] = { requiredXP = 55000, rewardFree = {gold = 50000}, rewardPremium = {gold = 125000} },
        [24] = { requiredXP = 60000, rewardFree = {gold = 50000}, rewardPremium = {gold = 125000} },
        [25] = { requiredXP = 65000, rewardFree = {items = {{8303, 1}}}, rewardPremium = {items = {{7708, 1}}, nexusCoins = 15} },
        [26] = { requiredXP = 71000, rewardFree = {gold = 60000}, rewardPremium = {gold = 150000} },
        [27] = { requiredXP = 77000, rewardFree = {gold = 60000}, rewardPremium = {gold = 150000} },
        [28] = { requiredXP = 83000, rewardFree = {gold = 60000}, rewardPremium = {gold = 150000} },
        [29] = { requiredXP = 89000, rewardFree = {gold = 60000}, rewardPremium = {gold = 150000} },
        [30] = { requiredXP = 95000, rewardFree = {taskPoints = 100}, rewardPremium = {taskPoints = 250} },
        [31] = { requiredXP = 102000, rewardFree = {gold = 70000}, rewardPremium = {gold = 175000} },
        [32] = { requiredXP = 109000, rewardFree = {gold = 70000}, rewardPremium = {gold = 175000} },
        [33] = { requiredXP = 116000, rewardFree = {gold = 70000}, rewardPremium = {gold = 175000} },
        [34] = { requiredXP = 123000, rewardFree = {gold = 70000}, rewardPremium = {gold = 175000} },
        [35] = { requiredXP = 130000, rewardFree = {gold = 1000000}, rewardPremium = {gold = 2000000, items = {{8473, 1}}} },
        [36] = { requiredXP = 139000, rewardFree = {gold = 80000}, rewardPremium = {gold = 200000} },
        [37] = { requiredXP = 148000, rewardFree = {gold = 80000}, rewardPremium = {gold = 200000} },
        [38] = { requiredXP = 157000, rewardFree = {gold = 80000}, rewardPremium = {gold = 200000} },
        [39] = { requiredXP = 166000, rewardFree = {gold = 80000}, rewardPremium = {gold = 200000} },
        [40] = { requiredXP = 175000, rewardFree = {taskPoints = 150}, rewardPremium = {items = {{1111, 1}}} },
        [41] = { requiredXP = 186000, rewardFree = {gold = 90000}, rewardPremium = {gold = 225000} },
        [42] = { requiredXP = 197000, rewardFree = {gold = 90000}, rewardPremium = {gold = 225000} },
        [43] = { requiredXP = 208000, rewardFree = {gold = 90000}, rewardPremium = {gold = 225000} },
        [44] = { requiredXP = 219000, rewardFree = {gold = 90000}, rewardPremium = {gold = 225000} },
        [45] = { requiredXP = 230000, rewardFree = {gold = 1500000}, rewardPremium = {gold = 3000000, items = {{7708, 2}}} },
        [46] = { requiredXP = 244000, rewardFree = {gold = 100000}, rewardPremium = {gold = 250000} },
        [47] = { requiredXP = 258000, rewardFree = {gold = 100000}, rewardPremium = {gold = 250000} },
        [48] = { requiredXP = 272000, rewardFree = {gold = 100000}, rewardPremium = {gold = 250000} },
        [49] = { requiredXP = 286000, rewardFree = {gold = 100000}, rewardPremium = {gold = 250000} },
        [50] = { requiredXP = 300000, rewardFree = {items = {{7708, 1}}}, rewardPremium = {items = {{2160, 50}}, nexusCoins = 20} },
    }
}
