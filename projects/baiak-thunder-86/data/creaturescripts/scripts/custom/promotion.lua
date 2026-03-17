function onAdvance(player, skill, oldLevel, newLevel)
    -- Só executa se for LEVEL e se for level 20 ou mais
    if skill ~= SKILL_LEVEL or newLevel < 20 then
        return true
    end

    local currentVoc = player:getVocation():getId()

    -- IDs das vocações base (Sorcerer, Druid, Paladin, Knight)
    -- Se o ID for entre 1 e 4, ele ainda não é promovido
    if currentVoc >= 1 and currentVoc <= 4 then
        local nextVocId = currentVoc + 4 -- Geralmente 1+4=5 (Master Sorcerer)
        
        player:setVocation(Vocation(nextVocId))
	player:sendTextMessage(MESSAGE_STATUS_WARNING, "Nexus System: Voce atingiu o level 20 e foi promovido gratuitamente!")
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    end

    return true
end