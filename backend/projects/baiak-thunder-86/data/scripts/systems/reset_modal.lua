--[[
    RESET SYSTEM MODAL - NEXUS EDITION
    Trata do comando !reset usando interface Modal.
]]

local config = {
    resetLevel = 1000,
    newLevel = 8,
    resetSkills = true, 
    benefits = {
        health = 100,           
        mana = 100,             
        capacity = 100,         
        criticalChance = 1,     
        dodgeChance = 0.5,      
        damageBonus = 1,        
    },
    skillLossPercentage = 30,
    STORAGE_RESET_COUNT = 50400,
    STORAGE_RESET_LOCK = 50401,
    STORAGE_SKILL_PROTECTION = 50404, -- Timer para o Scroll de Preservação
    MODAL_ID = 50400
}

local function getPlayerResets(player)
    return math.max(0, player:getStorageValue(config.STORAGE_RESET_COUNT))
end

-- ============================================================
-- COMANDO 1: !reset (AGORA ABRE A MODAL)
-- ============================================================
local resetModal = TalkAction("!reset")

function resetModal.onSay(player, words, param)
    local resets = getPlayerResets(player)
    
    local title = "Reset System - Nexus"
    local message = string.format("Voce possui %d resets.\n\n", resets)
    
    -- ANTI-SPAM LOCK: Prevent player from opening multiple modals or spamming commands while an event is scheduled
    if player:getStorageValue(50401) > os.time() then
        player:sendCancelMessage("Aguarde alguns segundos antes de tentar resetar novamente.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end
    
    if player:getLevel() < config.resetLevel then
        message = message .. string.format("Voce ainda nao tem level para resetar.\nLevel atual: %d / Necessario: %d.\n", player:getLevel(), config.resetLevel)
    else
        message = message .. string.format("Voce ja pode resetar! (Voltara para o level %d).\n", config.newLevel)
    end
    
    message = message .. "\n-- BONUS ATUAIS --\n"
    message = message .. string.format("+ %d HP | + %d MP | + %d Cap\n", resets * config.benefits.health, resets * config.benefits.mana, resets * config.benefits.capacity)
    message = message .. string.format("+ %.1f%% Dano | %.1f%% Critico | %.1f%% Dodge", resets * config.benefits.damageBonus, resets * config.benefits.criticalChance, resets * config.benefits.dodgeChance)

    local window = ModalWindow(config.MODAL_ID, title, message)
    
    window:addButton(100, "Confirmar")
    window:addButton(101, "Cancelar")
    
    window:setDefaultEnterButton(100)
    window:setDefaultEscapeButton(101)
    
    window:sendToPlayer(player)
    return false
end

resetModal:register()

-- ============================================================
-- RESPOSTA DA MODAL (!resetconfirm logic)
-- ============================================================
local resetModalEvent = CreatureEvent("ResetModalEv")
function resetModalEvent.onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId ~= config.MODAL_ID then
        return true
    end

    if buttonId == 100 then -- Confirmar
        if player:getLevel() < config.resetLevel then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Voce precisa do level " .. config.resetLevel .. " para resetar.")
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end

        local resetsPlus = getPlayerResets(player) + 1
        
        -- 1. SALVA CONTAGEM
        player:setStorageValue(config.STORAGE_RESET_COUNT, resetsPlus)
        
        -- 2. REDUÇÃO DE SKILLS (30% de perda ou 0% se tiver o Scroll ativo)
        if config.resetSkills then
            -- Verifica se o buff do Scroll de Preservação está ativo
            if player:getStorageValue(config.STORAGE_SKILL_PROTECTION) < os.time() then
                local lossMultiplier = config.skillLossPercentage / 100
                
                for i = 0, 6 do
                    local currentSkill = player:getSkillLevel(i)
                    if currentSkill > 10 then
                        local loss = math.floor(currentSkill * lossMultiplier)
                        player:addSkillLevel(i, -loss)
                    end
                end
                
                local currentML = player:getMagicLevel()
                if currentML > 0 then
                    local lossML = math.floor(currentML * lossMultiplier)
                    player:addMagicLevel(-lossML)
                end
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Seus skills foram reduzidos em " .. config.skillLossPercentage .. "% devido ao reset.")
            else
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Protecao de Skill detectada! Seus skills foram preservados.")
                -- Opcional: Consumir o buff logo após o uso ou deixar expirar por tempo
                -- player:setStorageValue(config.STORAGE_SKILL_PROTECTION, 0) 
            end
        end

        -- ANTI-SPAM LOCK: Blocks reset attempts and logic for 5 seconds
        if player:getStorageValue(50401) > os.time() then
            return true
        end
        player:setStorageValue(50401, os.time() + 5)
        
        local voc = player:getVocation()
        
        -- Até o level 8, o char ganha status como "Rookie" (sem vocação específica), por isso todos chegam iguais ao level 8.
        local baseH = 185
        local baseM = 35
        local baseCap = 470 -- 470 inicial 

        local newMaxH = baseH + (resetsPlus * config.benefits.health)
        local newMaxM = baseM + (resetsPlus * config.benefits.mana)
        local newCap = baseCap + (resetsPlus * config.benefits.capacity)
        local level8Exp = 4200
        local guid = player:getGuid()

        -- PREPARA O CHAR: Manda pro templo e avisa
        player:teleportTo(player:getTown():getTemplePosition())
        player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_RED)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Parabens! Voce alcancou o reset " .. resetsPlus .. ". Voce sera deslogado para aplicar as mudancas.")
        
        -- CLEAR UPGRADE SYSTEM BONUSES: Prevent mathematical underflow on next login
        player:setStorageValue(50501, 0) -- HP Bonus
        player:setStorageValue(50502, 0) -- Mana Bonus
        player:setStorageValue(50503, 0) -- Speed Bonus

        -- INSTANTANEOUS EXPLOT LOCKOUT: Lock their login using engine-level RAM Storage
        Game.setStorageValue(2000000 + guid, os.time() + 5)
        
        -- Kick the player
        addEvent(function(pId)
            local p = Player(pId)
            if p then p:remove() end
        end, 500, player:getId())
        
        -- Clear Upgrade System storages to fix already bugged characters
        player:setStorageValue(50501, 0)
        player:setStorageValue(50502, 0)
        player:setStorageValue(50503, 0)
        
        -- Run the offline DB query to wipe them to Level 8 and 0 resets
        addEvent(function(playerGuid, pExp, pMaxH, pMaxM, pCap)
            db.query(string.format("UPDATE `players` SET `level` = 8, `experience` = %d, `health` = %d, `healthmax` = %d, `mana` = %d, `manamax` = %d, `cap` = %d WHERE `id` = %d", pExp, pMaxH, pMaxH, pMaxM, pMaxM, pCap, playerGuid))
        end, 1500, guid, level8Exp, newMaxH, newMaxM, newCap)
    end

    -- Remover target para evitar loops se botão cancelar (101)
    return true
end

resetModalEvent:register()

local resetLoginEvent = CreatureEvent("ResetModalLogin")
function resetLoginEvent.onLogin(player)
    player:registerEvent("ResetModalEv")
    return true
end
resetLoginEvent:register()

-- ============================================================
-- COMANDO ADMIN PARA CORRIGIR STATUS BUGADOS
-- ============================================================
local fixStatsModal = TalkAction("/fixresets")

function fixStatsModal.onSay(player, words, param)
    if not player:getGroup():getAccess() then return true end

    local target = Player(param)
    if not target then
        player:sendCancelMessage("Jogador nao encontrado. Use /fixresets NomeDoJogador")
        return false
    end

    local resets = math.max(0, target:getStorageValue(config.STORAGE_RESET_COUNT))
    local voc = target:getVocation()
    
    -- ADMINISTRADOR FORÇANDO RESET TOTAL: Remove TODOS os resets e bota level 8 base.
    target:setStorageValue(config.STORAGE_RESET_COUNT, 0)
    
    -- Status Base APENAS (Level 8, 0 Resets)
    local baseH = 185
    local baseM = 35
    local baseCap = 470
    
    local level8Exp = 4200
    local guid = target:getGuid()
    
    -- O GOD usou o comando em alguém online. Precisamos kickar igual o reset normal para evitar bugs C++
    target:teleportTo(target:getTown():getTemplePosition())
    target:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voce forcou a zerar os resets de " .. target:getName() .. ". Ele sera deslogado para aplicar a punicao/correcao.")
    
    target:save()
    target:remove()
    
    addEvent(function(playerGuid, pExp, pMaxH, pMaxM, pCap)
        db.query(string.format("UPDATE `players` SET `level` = 8, `experience` = %d, `health` = %d, `healthmax` = %d, `mana` = %d, `manamax` = %d, `cap` = %d WHERE `id` = %d", pExp, pMaxH, pMaxH, pMaxM, pMaxM, pCap, playerGuid))
        -- Também precisamos deletar/setar o storage no banco caso ele estivesse offline depois
        db.query(string.format("INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES (%d, %d, 0) ON DUPLICATE KEY UPDATE `value` = 0", playerGuid, config.STORAGE_RESET_COUNT))
    end, 1500, guid, level8Exp, baseH, baseM, baseCap)
    return false
end

fixStatsModal:separator(" ")
fixStatsModal:register()
