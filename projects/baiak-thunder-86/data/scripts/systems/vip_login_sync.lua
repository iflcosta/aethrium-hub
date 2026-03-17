local vipSync = CreatureEvent("VipSyncDatabase")

function vipSync.onLogin(player)
    local accountId = player:getAccountId()
    
    -- Consulta os dias e o tier que o site entregou
    local resultId = db.storeQuery("SELECT `vip_days`, `vip_tier` FROM `accounts` WHERE `id` = " .. accountId)
    
    if resultId then
        local days = result.getDataInt(resultId, "vip_days")
        local tier = result.getDataInt(resultId, "vip_tier")
        result.free(resultId)
        
        if days > 0 then
            -- Se o site não enviou um tier (0), definimos como 1 (Bronze) por padrão
            local targetTier = (tier >= 1 and tier <= 3) and tier or 1
            
            -- CHAMA A FUNÇÃO DO SEU VIP_SYSTEM.LUA:
            -- addVip(player, tier, dias)
            addVip(player, targetTier, days)
            
            -- Limpa os dados na conta para não repetir o processo
            db.query("UPDATE `accounts` SET `vip_days` = 0, `vip_tier` = 0 WHERE `id` = " .. accountId)
            
            local tierName = (targetTier == 3 and "Ouro") or (targetTier == 2 and "Prata") or "Bronze"
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Logistica Nexus: Voce recebeu " .. days .. " dias de VIP " .. tierName .. "!")
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
        end
    end
    return true
end

vipSync:register()