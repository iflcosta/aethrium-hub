local config = {
    -- Defina os IDs das exercise weapons aqui
    exerciseWeapons = {
        -- Swords
        [31208] = {skill = SKILL_SWORD, effect = CONST_ME_HITAREA},
        [37935] = {skill = SKILL_SWORD, effect = CONST_ME_HITAREA, durable = true},
        [37941] = {skill = SKILL_SWORD, effect = CONST_ME_HITAREA, lasting = true},

        -- Axes
        [31209] = {skill = SKILL_AXE, effect = CONST_ME_HITAREA},
        [37936] = {skill = SKILL_AXE, effect = CONST_ME_HITAREA, durable = true},
        [37942] = {skill = SKILL_AXE, effect = CONST_ME_HITAREA, lasting = true},

        -- Clubs
        [31210] = {skill = SKILL_CLUB, effect = CONST_ME_HITAREA},
        [37937] = {skill = SKILL_CLUB, effect = CONST_ME_HITAREA, durable = true},
        [37943] = {skill = SKILL_CLUB, effect = CONST_ME_HITAREA, lasting = true},

        -- Distance
        [31211] = {skill = SKILL_DISTANCE, effect = CONST_ME_HITBYPOISON},
        [37938] = {skill = SKILL_DISTANCE, effect = CONST_ME_HITBYPOISON, durable = true},
        [37944] = {skill = SKILL_DISTANCE, effect = CONST_ME_HITBYPOISON, lasting = true},

        -- Magic Level (Rods)
        [31212] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA},
        [37939] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA, durable = true},
        [37945] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA, lasting = true},

        -- Magic Level (Wands)
        [31213] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA},
        [37940] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA, durable = true},
        [37946] = {skill = SKILL_MAGLEVEL, effect = CONST_ME_ENERGYAREA, lasting = true}
    }
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local weaponConfig = config.exerciseWeapons[item:getId()]

    if not weaponConfig then
        return false
    end

    if not target or not target:isItem() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to use this on an exercise dummy.")
        return true
    end

    -- Verifica se é um exercise dummy (IDs comuns: 28552, 28557)
    local dummyIds = {31214, 28557, 28558, 28559, 28560}
    local isDummy = false

    for _, id in ipairs(dummyIds) do
        if target:getId() == id then
            isDummy = true
            break
        end
    end

    if not isDummy then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can only use this on an exercise dummy.")
        return true
    end

    -- Verifica se já está treinando
    if player:getStorageValue(STORAGEVALUE_EXERCISETRAINING) > os.time() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are already training.")
        return true
    end

    local charges = item:getAttribute(ITEM_ATTRIBUTE_CHARGES) or 500

    if charges <= 0 then
        item:remove(1)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your exercise weapon broke.")
        return true
    end

    -- Remove 1 charge
    charges = charges - 1
    item:setAttribute(ITEM_ATTRIBUTE_CHARGES, charges)

    -- Efeito visual
    toPosition:sendMagicEffect(weaponConfig.effect)

    -- Ganha skill
    player:addSkillTries(weaponConfig.skill, player:getVocation():getRequiredSkillTries(weaponConfig.skill, player:getSkillLevel(weaponConfig.skill)))

    -- Atualiza storage
    player:setStorageValue(STORAGEVALUE_EXERCISETRAINING, os.time() + 2)

    if charges <= 0 then
        item:remove(1)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your exercise weapon broke.")
    end

    return true
end
