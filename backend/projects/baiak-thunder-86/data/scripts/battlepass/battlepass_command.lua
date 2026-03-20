local battlepass = TalkAction("!battlepass", "!bp")

function formatNumberWithCommas(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return tostring(formatted)
end

function getRewardString(data)
    local str = ""
    if data.gold then str = str .. formatNumberWithCommas(data.gold) .. " Gold\n" end
    if data.taskPoints then str = str .. data.taskPoints .. " Task Points\n" end
    if data.nexusCoins then str = str .. data.nexusCoins .. " Nexus Coins\n" end
    if data.items then
        for _, it in ipairs(data.items) do
            str = str .. it[2] .. "x " .. ItemType(it[1]):getName() .. "\n"
        end
    end
    if str == "" then return "Nenhuma" end
    return str
end

function battlepass.onSay(player, words, param)
    -- Lógica de inicialização e resete de season ficaria aqui
    -- Como simplificamos na task, vamos direto ao painel
    local level = player:getStorageValue(BATTLEPASS_CONFIG.storageLevel)
    if level < 0 then level = 1 end
    
    local data = BATTLEPASS_CONFIG.levels[level]
    if not data then
        player:sendCancelMessage("Voce completou todos os niveis do Aethrium Pass!")
        return false
    end
    
    local currentXp = math.max(0, player:getStorageValue(BATTLEPASS_CONFIG.storageXp))
    local passType = player:getStorageValue(BATTLEPASS_CONFIG.storagePremium)
    local isPremium = (passType == 2)
    local statusAcc = isPremium and "[ PREMIUM ]" or "[ FREE ]"
    
    local msg = string.format("Status da Conta: %s\nNivel Atual: %d / %d\nProgresso de XP: %s / %s",
        statusAcc, level, BATTLEPASS_CONFIG.maxLevel,
        formatNumberWithCommas(currentXp), formatNumberWithCommas(data.requiredXP)
    )
    
    local window = ModalWindow(1001, "Aethrium Pass - Status", msg)
    
    window:addButton(1, "Resgatar")
    window:setDefaultEnterButton(1)
    
    if not isPremium then
        local vipTier = math.max(0, player:getStorageValue(50200))
        local finalPrice = BATTLEPASS_CONFIG.pricing[vipTier] or BATTLEPASS_CONFIG.pricing[0]
        window:addButton(2, "Comprar Premium (" .. finalPrice .. " Nexus Coins)")
    end
    
    window:addButton(3, "Fechar")
    
    local freeStr = getRewardString(data.rewardFree)
    local premStr = getRewardString(data.rewardPremium)
    
    window:addChoice(1, ">> PROXIMO NIVEL REWARDS <<")
    window:addChoice(2, "- FREE -")
    for line in freeStr:gmatch("([^\n]*)\n?") do
        if line ~= "" then window:addChoice(3, line) end
    end
    
    window:addChoice(4, "- PREMIUM -")
    for line in premStr:gmatch("([^\n]*)\n?") do
        if line ~= "" then window:addChoice(5, line) end
    end
    
    window:sendToPlayer(player)
    return false
end

battlepass:separator(" ")
battlepass:register()
