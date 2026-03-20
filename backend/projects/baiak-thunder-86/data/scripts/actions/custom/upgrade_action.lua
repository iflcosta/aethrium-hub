--[[
    SISTEMA DE UPGRADE DE ITENS - Action (Fase 2)
    Baiak Thunder (Refatorado)
]]

local upgradeAction = Action()

-- ============================================================
-- FORWARD DECLARATIONS
-- ============================================================
local sendTierConfirmMenu
local processTierUpgrade
local sendAttributeSlotMenu
local sendAttributeConfirmMenu
local processAttributeUpgrade

-- ============================================================
-- TIER: CONFIRMACAO
-- ============================================================
function sendTierConfirmMenu(player, targetItem, isMinor)
    local currentTier = UPGRADE_SYSTEM:getItemTier(targetItem)
    local nextTier = currentTier + 1
    
    if isMinor and currentTier >= 5 then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "O Minor Crystal so pode ser usado em itens ate o Tier +4 (para subir ao +5). Use o Flawless Crystal.")
    end
    
    if not isMinor and currentTier < 5 then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "O Flawless Crystal so pode ser usado em itens a partir do Tier +5. Use o Minor Crystal.")
    end
    
    if nextTier > UPGRADE_SYSTEM.tiers.maxTier then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format(UPGRADE_SYSTEM.messages.maxTier, UPGRADE_SYSTEM.tiers.maxTier))
    end
    
    local tierData = UPGRADE_SYSTEM.tiers.upgrades[nextTier]
    local reqCrystalName = isMinor and "Minor Crystal" or "Flawless Crystal"
    local hasProtection = UPGRADE_SYSTEM:hasProtection(player)
    
    local function buttonCallback(player, button, choice)
        if not choice then return end
        if button.text == "Confirmar" then
            processTierUpgrade(player, targetItem, isMinor)
        elseif button.text == "Alternar Protecao" then
            UPGRADE_SYSTEM:setProtection(player, not hasProtection)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Auto-Protecao " .. (not hasProtection and "ATIVADA" or "DESATIVADA") .. "!")
            sendTierConfirmMenu(player, targetItem, isMinor)
        end
    end
    
    local protectionTxt = "DESATIVADA"
    local pentalyTxt = ""
    if hasProtection then
        protectionTxt = "ATIVADA (Requer 1 Protection Scroll no inv)"
        pentalyTxt = "Nenhuma (Protegido)"
    else
        if tierData.penalty == 0 then pentalyTxt = "Nenhuma (Safe Tier)"
        elseif tierData.penalty == 1 then pentalyTxt = "-1 Tier"
        else pentalyTxt = "-2 Tiers" end
    end
    
    local msg = string.format([[
Item: %s
Progresso: -> +%d

Custo:
- %s: 1
- Gold: %s

Chance de Sucesso: %d%%
Auto Protecao: %s
Em caso de falha: %s
]], UPGRADE_SYSTEM:formatItemName(targetItem), nextTier, reqCrystalName, UPGRADE_SYSTEM:formatNumber(tierData.gold), tierData.chance, protectionTxt, pentalyTxt)
    
    local window = ModalWindow { title = "Confirmar Tier", message = msg }
    window:addButton("Fechar")
    window:addButton("Alternar Protecao", buttonCallback)
    window:addButton("Confirmar", buttonCallback)
    window:addChoice("Tentar Upgrade de Tier")
    window:setDefaultEnterButton("Confirmar")
    window:setDefaultEscapeButton("Fechar")
    window:sendToPlayer(player)
end

function processTierUpgrade(player, targetItem, isMinor)
    if not targetItem then return end
    if targetItem:getTopParent() ~= player then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Erro: O item foi movido do seu inventario.")
        return
    end
    if UPGRADE_SYSTEM:isCracked(targetItem) then return player:sendTextMessage(MESSAGE_STATUS_SMALL, UPGRADE_SYSTEM.messages.itemCracked) end
    
    local itemType = targetItem:getType()
    local slotPos = itemType and itemType:getSlotPosition()
    if not slotPos or not UPGRADE_SYSTEM:canUpgradeItem(targetItem, slotPos) then return end
    
    local currentTier = UPGRADE_SYSTEM:getItemTier(targetItem)
    local nextTier = currentTier + 1
    if nextTier > UPGRADE_SYSTEM.tiers.maxTier then return end
    
    if isMinor and currentTier >= 5 then return end
    if not isMinor and currentTier < 5 then return end
    
    local tierData = UPGRADE_SYSTEM.tiers.upgrades[nextTier]
    if player:getMoney() < tierData.gold then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format(UPGRADE_SYSTEM.messages.noGold, UPGRADE_SYSTEM:formatNumber(tierData.gold)))
    end
    
    local reqCrystalId = isMinor and UPGRADE_SYSTEM.items.minorCrystal or UPGRADE_SYSTEM.items.flawlessCrystal
    if player:getItemCount(reqCrystalId) < 1 then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, isMinor and "Falta Minor Crystal." or "Falta Flawless Crystal.")
    end
    
    -- Consume protection scroll if toggle is on
    local hasProtection = UPGRADE_SYSTEM:hasProtection(player)
    local savedByProt = false
    if hasProtection then
        if player:removeItem(UPGRADE_SYSTEM.items.protectionScroll, 1) then
            savedByProt = true
        else
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Aviso] Protecao ativa, mas voce nao tinha o scroll. Upgrade sera feito sem protecao.")
        end
    end
    
    if not player:removeMoney(tierData.gold) then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "Ocorreu um erro ao remover seu gold.")
    end
    
    if not player:removeItem(reqCrystalId, 1) then
        player:addMoney(tierData.gold)
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "Ocorreu um erro ao remover seu crystal.")
    end
    
    if math.random(100) <= tierData.chance then
        UPGRADE_SYSTEM:setItemTier(targetItem, nextTier)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(UPGRADE_SYSTEM.messages.upgradeSuccess, nextTier))
        player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
    else
        if savedByProt then
            local msg = UPGRADE_SYSTEM.messages.upgradeFailProtected or "FALHA! Porem nada aconteceu pois o protection scroll protegeu seu tier."
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        else
            if tierData.penalty == 0 then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, UPGRADE_SYSTEM.messages.upgradeFailSafe)
            else
                local newTier = math.max(0, currentTier - tierData.penalty)
                UPGRADE_SYSTEM:setItemTier(targetItem, newTier)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(UPGRADE_SYSTEM.messages.upgradeFail, newTier))
            end
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        end
    end
end

-- ============================================================
-- ATRIBUTOS: SELECAO DE SLOT E CONFIRMACAO
-- ============================================================
function sendAttributeSlotMenu(player, targetItem, isBasicMode)
    local function buttonCallback(player, button, choice)
        if not choice then return end
        if button.text == "Selecionar" then
            sendAttributeConfirmMenu(player, targetItem, choice.id, isBasicMode)
        end
    end
    
    local reqStone = isBasicMode and "Basic Attribute Stone" or "Greater Attribute Stone"
    local window = ModalWindow { title = "Gerenciar Atributos", message = "Pedra Utilizada: " .. reqStone .. "\nEscolha o slot para melhorar/descobrir:\n" }
    window:addButton("Fechar")
    window:addButton("Selecionar", buttonCallback)
    
    for i = 1, UPGRADE_SYSTEM.attributes.maxSlots do
        local attrData = UPGRADE_SYSTEM:getSlotAttribute(targetItem, i)
        if attrData then
            local def = UPGRADE_SYSTEM.attributes.list[attrData.key]
            local name = def and def.name or attrData.key
            window:addChoice("Slot " .. i .. ": " .. name .. " (Lv." .. attrData.level .. "/" .. UPGRADE_SYSTEM.attributes.maxLevel .. ")")
        else
            window:addChoice("Slot " .. i .. ": VAZIO (Descobrir)")
        end
    end
    
    window:setDefaultEnterButton("Selecionar")
    window:setDefaultEscapeButton("Fechar")
    window:sendToPlayer(player)
end

function sendAttributeConfirmMenu(player, targetItem, attrSlotIdx, isBasicMode)
    local attrData = UPGRADE_SYSTEM:getSlotAttribute(targetItem, attrSlotIdx)
    local targetLevel = attrData and (attrData.level + 1) or 1
    
    if targetLevel > UPGRADE_SYSTEM.attributes.maxLevel then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Este slot ja esta no nível maximo!")
        return sendAttributeSlotMenu(player, targetItem, isBasicMode)
    end
    
    if isBasicMode and targetLevel > 3 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "A Basic Attribute Stone so funciona ate o nivel 3. Use a Greater Attribute Stone para niveis maiores.")
        return sendAttributeSlotMenu(player, targetItem, isBasicMode)
    end
    
    if not isBasicMode and targetLevel <= 3 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "A Greater Attribute Stone so pode ser usada a partir do nivel 4. Use a Basic Attribute Stone nos niveis inicias.")
        return sendAttributeSlotMenu(player, targetItem, isBasicMode)
    end
    
    local reqStoneName = isBasicMode and "Basic Attribute Stone" or "Greater Attribute Stone"
    local levelData = UPGRADE_SYSTEM.attributes.levels[targetLevel]
    local hasProtection = UPGRADE_SYSTEM:hasProtection(player)
    
    local function buttonCallback(player, button, choice)
        if not choice then return end
        if button.text == "Voltar" then return sendAttributeSlotMenu(player, targetItem, isBasicMode) end
        if button.text == "Confirmar" then 
            processAttributeUpgrade(player, targetItem, attrSlotIdx, isBasicMode)
        elseif button.text == "Alternar Protecao" then
            UPGRADE_SYSTEM:setProtection(player, not hasProtection)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Auto-Protecao " .. (not hasProtection and "ATIVADA" or "DESATIVADA") .. "!")
            sendAttributeConfirmMenu(player, targetItem, attrSlotIdx, isBasicMode)
        end
    end
    
    local protectionTxt = "DESATIVADA"
    if hasProtection then protectionTxt = "ATIVADA (Previne Quebra, consome 1 Protection Scroll)" end
    
    local currentText = attrData and string.format("%s Lv.%d", UPGRADE_SYSTEM.attributes.list[attrData.key].name, attrData.level) or "VAZIO"
    local targetText = attrData and string.format("Lv.%d", targetLevel) or "Descoberta (RNG Lv.1)"
    
    local msg = string.format([[
Slot: %d
Atual: %s
Objetivo: %s

Custo:
- %s: 1
- Gold: %s

Chances:
- Sucesso: %d%%
- Falha Comum (Pedra quebra): %d%%
- Falha Critica (Trincar Item): %d%%

Auto Protecao: %s
]], attrSlotIdx, currentText, targetText, reqStoneName, UPGRADE_SYSTEM:formatNumber(UPGRADE_SYSTEM.attributes.goldCost), levelData.success, levelData.commonFail, levelData.criticalFail, protectionTxt)

    local window = ModalWindow { title = "Upgrade Slot " .. attrSlotIdx, message = msg }
    window:addButton("Voltar", buttonCallback)
    window:addButton("Fechar")
    window:addButton("Alternar Protecao", buttonCallback)
    window:addButton("Confirmar", buttonCallback)
    window:addChoice("Tentar Evolucao")
    window:setDefaultEnterButton("Confirmar")
    window:setDefaultEscapeButton("Fechar")
    window:sendToPlayer(player)
end

function processAttributeUpgrade(player, targetItem, attrSlotIdx, isBasicMode)
    if not targetItem then return end
    if targetItem:getTopParent() ~= player then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Erro: O item foi movido do seu inventario.")
        return
    end
    if UPGRADE_SYSTEM:isCracked(targetItem) then return end
    
    local attrData = UPGRADE_SYSTEM:getSlotAttribute(targetItem, attrSlotIdx)
    local targetLevel = attrData and (attrData.level + 1) or 1
    
    if targetLevel > UPGRADE_SYSTEM.attributes.maxLevel then return end
    if isBasicMode and targetLevel > 3 then return end
    if not isBasicMode and targetLevel <= 3 then return end
    
    local goldReq = UPGRADE_SYSTEM.attributes.goldCost
    if player:getMoney() < goldReq then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, string.format(UPGRADE_SYSTEM.messages.noGold, UPGRADE_SYSTEM:formatNumber(goldReq)))
    end
    
    local reqStoneId = isBasicMode and UPGRADE_SYSTEM.items.basicAttributeStone or UPGRADE_SYSTEM.items.greaterAttributeStone
    if player:getItemCount(reqStoneId) < 1 then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, isBasicMode and UPGRADE_SYSTEM.messages.noBasic or UPGRADE_SYSTEM.messages.noGreater)
    end
    
    local levelData = UPGRADE_SYSTEM.attributes.levels[targetLevel]
    
    -- Consume protection
    local hasProtection = UPGRADE_SYSTEM:hasProtection(player)
    local savedByProt = false
    if hasProtection then
        if player:removeItem(UPGRADE_SYSTEM.items.protectionScroll, 1) then
            savedByProt = true
        else
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Aviso] Protecao ativa, mas voce nao tinha o scroll. Tentando sem protecao!")
        end
    end
    
    if not player:removeMoney(goldReq) then
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "Ocorreu um erro ao remover seu gold.")
    end
    
    if not player:removeItem(reqStoneId, 1) then
        player:addMoney(goldReq)
        return player:sendTextMessage(MESSAGE_STATUS_SMALL, "Ocorreu um erro ao remover sua attribute stone.")
    end
    
    local roll = math.random(100)
    
    if roll <= levelData.success then
        -- SUCESSO
        if not attrData then
            -- Descobrir
            local validAttrs = UPGRADE_SYSTEM:getValidAttributesForItem(targetItem, player:getVocation():getId())
            if #validAttrs == 0 then
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Este item nao suporta nenhum atributo para sua vocacao.")
                return
            end
            local chosen = validAttrs[math.random(#validAttrs)]
            UPGRADE_SYSTEM:setSlotAttribute(targetItem, attrSlotIdx, chosen, 1)
            local def = UPGRADE_SYSTEM.attributes.list[chosen]
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(UPGRADE_SYSTEM.messages.attrDiscover, def.name, attrSlotIdx))
        else
            -- Evoluir
            UPGRADE_SYSTEM:setSlotAttribute(targetItem, attrSlotIdx, attrData.key, targetLevel)
            local def = UPGRADE_SYSTEM.attributes.list[attrData.key]
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(UPGRADE_SYSTEM.messages.attrSuccess, def.name, targetLevel))
        end
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        
    elseif roll <= (levelData.success + levelData.commonFail) then
        -- FALHA COMUM
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, UPGRADE_SYSTEM.messages.attrFailCommon)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    else
        -- FALHA CRITICA
        if savedByProt then
            local msg = UPGRADE_SYSTEM.messages.attrFailProtected or "FALHA! A pedra quebrou, mas o protection scroll salvou o item de trincar."
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        else
            UPGRADE_SYSTEM:setCracked(targetItem, true)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, UPGRADE_SYSTEM.messages.attrFailCritical)
            player:getPosition():sendMagicEffect(CONST_ME_EXPLOSIONHIT)
        end
    end
end

-- ============================================================
-- ON USE (ACTION EVENT)
-- ============================================================
function upgradeAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or type(target) ~= "userdata" or not target:isItem() then
        player:sendCancelMessage("Você precisa usar este item em um equipamento.")
        return true
    end
    
    local targetItem = target
    
    local slotPos = targetItem:getType() and targetItem:getType():getSlotPosition()
    if not slotPos or not UPGRADE_SYSTEM:canUpgradeItem(targetItem, slotPos) then
        player:sendCancelMessage(UPGRADE_SYSTEM.messages.cantUpgrade)
        return true
    end
    
    if UPGRADE_SYSTEM:isCracked(targetItem) then
        player:sendCancelMessage(UPGRADE_SYSTEM.messages.itemCracked)
        return true
    end
    
    local itemId = item:getId()
    if itemId == UPGRADE_SYSTEM.items.minorCrystal then
        sendTierConfirmMenu(player, targetItem, true)
    elseif itemId == UPGRADE_SYSTEM.items.flawlessCrystal then
        sendTierConfirmMenu(player, targetItem, false)
    elseif itemId == UPGRADE_SYSTEM.items.basicAttributeStone then
        sendAttributeSlotMenu(player, targetItem, true)
    elseif itemId == UPGRADE_SYSTEM.items.greaterAttributeStone then
        sendAttributeSlotMenu(player, targetItem, false)
    end
    
    return true
end

upgradeAction:id(
    UPGRADE_SYSTEM.items.minorCrystal,
    UPGRADE_SYSTEM.items.flawlessCrystal,
    UPGRADE_SYSTEM.items.basicAttributeStone,
    UPGRADE_SYSTEM.items.greaterAttributeStone
)
upgradeAction:register()

print("[Upgrade System] Action Upgrade (Fase 2) registrada com sucesso!")
