local config = {
    -- Water tiles
    waterIds = {
        618, 619, 620, 621, 622, 623, 624, 625, 626, 627, 628, 629, 630, 631, 632, 633,
        634, 635, 636, 4608, 4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616, 4617, 4618,
        4619, 4620, 4621, 4622, 4623, 4624, 4625
    },

    -- Fishing rewards by skill level
    rewards = {
        -- Common fish (skill 0-20)
        {minSkill = 0, maxSkill = 20, items = {
            {id = 2667, chance = 40}, -- fish
            {id = 2669, chance = 30}, -- northern pike
            {id = 2666, chance = 20}, -- meat
            {id = 2148, count = {1, 5}, chance = 10} -- gold coins
        }},

        -- Uncommon fish (skill 20-50)
        {minSkill = 20, maxSkill = 50, items = {
            {id = 2669, chance = 30}, -- northern pike
            {id = 7159, chance = 25}, -- rainbow trout
            {id = 2667, chance = 20}, -- fish
            {id = 2148, count = {5, 15}, chance = 15}, -- gold coins
            {id = 2376, chance = 10} -- sword (rare)
        }},

        -- Rare fish (skill 50+)
        {minSkill = 50, maxSkill = 100, items = {
            {id = 7159, chance = 30}, -- rainbow trout
            {id = 2669, chance = 25}, -- northern pike
            {id = 5895, chance = 15}, -- fish fin
            {id = 2148, count = {10, 30}, chance = 15}, -- gold coins
            {id = 2376, chance = 10}, -- sword
            {id = 2487, chance = 5} -- crown helmet (very rare)
        }}
    },

    -- Special items (very rare, any skill)
    specialRewards = {
        {id = 2159, chance = 0.1}, -- obsidian lance
        {id = 2160, count = {1, 3}, chance = 0.5}, -- crystal coin
        {id = 2195, chance = 0.3}, -- boots of haste
        {id = 7158, chance = 1}, -- rainbow shield
        {id = 7632, chance = 2} -- giant shimmering pearl
    },

    -- Junk items
    junkItems = {
        {id = 2148, count = {1, 3}, chance = 30}, -- few gold coins
        {id = 2667, chance = 25}, -- fish
        {id = 2666, chance = 20}, -- meat
        {id = 2376, chance = 15}, -- old sword
        {id = 3976, chance = 10} -- worm
    },

    -- Config
    skillTries = 1,
    baseChance = 10, -- 10% base chance to catch something
    skillMultiplier = 0.597,
    maxChance = 50 -- 50% max chance
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Check if target is water
    if not table.contains(config.waterIds, target.itemid) then
        return false
    end

    -- Check if player is next to water
    if not Position(toPosition):isSightClear(player:getPosition()) then
        player:sendCancelMessage("You need to be closer to the water.")
        return true
    end

    -- Calculate fishing chance
    local playerSkill = player:getSkillLevel(SKILL_FISHING)
    local fishingChance = math.min(
        math.max(config.baseChance + playerSkill * config.skillMultiplier, config.baseChance),
        config.maxChance
    )

    -- Try to fish
    if math.random(100) > fishingChance then
        -- Failed to catch anything
        toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
        player:addSkillTries(SKILL_FISHING, config.skillTries)
        return true
    end

    -- Success! Determine what was caught
    local caughtItem = nil

    -- 5% chance for special reward
    if math.random(1000) <= 50 then
        local totalChance = 0
        for _, reward in ipairs(config.specialRewards) do
            totalChance = totalChance + reward.chance
        end

        local random = math.random(totalChance * 100) / 100
        local currentChance = 0

        for _, reward in ipairs(config.specialRewards) do
            currentChance = currentChance + reward.chance
            if random <= currentChance then
                caughtItem = reward
                break
            end
        end
    end

    -- If no special reward, get normal reward based on skill
    if not caughtItem then
        local rewardTable = nil
        for _, rewards in ipairs(config.rewards) do
            if playerSkill >= rewards.minSkill and playerSkill <= rewards.maxSkill then
                rewardTable = rewards.items
                break
            end
        end

        -- Fallback to junk if no table found
        if not rewardTable then
            rewardTable = config.junkItems
        end

        -- Calculate total chance
        local totalChance = 0
        for _, reward in ipairs(rewardTable) do
            totalChance = totalChance + reward.chance
        end

        -- Pick random item
        local random = math.random(totalChance)
        local currentChance = 0

        for _, reward in ipairs(rewardTable) do
            currentChance = currentChance + reward.chance
            if random <= currentChance then
                caughtItem = reward
                break
            end
        end
    end

    -- Add item to player
    if caughtItem then
        local count = 1
        if caughtItem.count then
            count = math.random(caughtItem.count[1], caughtItem.count[2])
        end

        local item = player:addItem(caughtItem.id, count)
        if item then
            local itemType = ItemType(caughtItem.id)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                string.format("You caught %s%s.", 
                    count > 1 and count .. " " or (itemType:getArticle() ~= "" and itemType:getArticle() .. " " or ""),
                    count > 1 and itemType:getPluralName() or itemType:getName()
                )
            )
            toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
        else
            player:sendCancelMessage("You don't have enough capacity.")
        end
    end

    -- Add skill tries
    player:addSkillTries(SKILL_FISHING, config.skillTries)

    return true
end
