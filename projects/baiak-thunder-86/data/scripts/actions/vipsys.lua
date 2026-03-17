--[[
    NEXUS VIP SYSTEM - ITEM ACTIVATION (Sincronizado com vip_system.lua)
    IDs selecionados: Bronze (10135), Silver (10134), Gold (10133)
]]

local actionVip = Action()

function actionVip.onUse(player, item, fromPosition, target, isHotkey)
    -- Mapeamento dos itens para as configurações do seu sistema existente
    local vipConfig = {
        [10135] = {tier = 1, days = 30, name = "VIP Bronze", effect = CONST_ME_YELLOWENERGY},
        [10134] = {tier = 2, days = 30, name = "VIP Silver", effect = CONST_ME_PURPLEENERGY},
        [10133] = {tier = 3, days = 30, name = "VIP Gold", effect = CONST_ME_HOLYDAMAGE}
    }

    local config = vipConfig[item:getId()]
    if not config then 
        return false 
    end

    -- Utiliza a função global addVip definida no seu vip_system.lua
    -- Isso garante que XP bônus e Loot funcionem imediatamente
    addVip(player, config.tier, config.days)
    
    -- Mensagem adicional de confirmação com a data de expiração
    local endTime = getVipEndTime(player)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, 
        string.format("[Nexus] Sua %s agora expira em: %s", config.name, os.date("%d/%m/%Y %H:%M", endTime)))
    
    -- Efeito visual definido no seu arquivo de sistema
    player:getPosition():sendMagicEffect(config.effect)
    
    -- Remove o item (scroll/medalha) após o uso
    item:remove(1)
    return true
end

-- Registro automático para os 3 IDs
actionVip:id(10135, 10134, 10133)
actionVip:register()