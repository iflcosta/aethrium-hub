if not slotMachineData then
	slotMachineData = {
		cost = 50000,
		-- Prizes: 
		-- Prizes with weights (The higher the weight, the common the item)
		items = {
			{id = 22472, weight = 100}, -- Minor Crystal
			{id = 8306,  weight = 100}, -- Basic Stone
			{id = 5944,  weight = 100}, -- Soul Orb
			{id = 9971,  weight = 100}, -- Gold Ingot
			{id = 5957,  weight = 100}, -- Lottery Ticket
			{id = 22473, weight = 30},  -- Flawless Crystal
			{id = 8300,  weight = 30},  -- Greater Stone
			{id = 25377, weight = 30},  -- Gold Token
			{id = 8303,  weight = 10},  -- Repair Hammer
			{id = 48946, weight = 5},   -- Aethrium Essence
		},

		positions = {
			Position(951, 1210, 6),
			Position(951, 1209, 6),
			Position(951, 1208, 6)
		},
		positionEffectDice = {
			Position(952, 1210, 6),
			Position(952, 1208, 6),
		},

		rolled = {},
		EXHAUST_STORAGE = 50902
	}
end

local positions = slotMachineData.positions
local function drawEffects()
	local n = 0
	local function decrease()
		if slotMachineData.owner then
			return
		end
		local t = 20 - n
		if t > 0 then
			n = n + 1
			for _, position in ipairs(positions) do
				position:sendMagicEffect(math.random(CONST_ME_GIFT_WRAPS, CONST_ME_FIREWORK_BLUE))
			end
			addEvent(decrease, 850)
		end
	end
	decrease()
end

local function checkEquals(itemTable)
    if #itemTable < 2 then return false, 0 end
    local first = itemTable[1]
    for i = 2, #itemTable do
        if itemTable[i] ~= first then
            return false, 0
        end
    end
	return true, first
end

local function getWeightedRandomItem(itemsTable)
    local totalWeight = 0
    for _, item in ipairs(itemsTable) do
        totalWeight = totalWeight + item.weight
    end

    local randomWeight = math.random(totalWeight)
    local currentWeight = 0
    for _, item in ipairs(itemsTable) do
        currentWeight = currentWeight + item.weight
        if randomWeight <= currentWeight then
            return item.id
        end
    end
    -- Fallback to first item id
    return itemsTable[1] and itemsTable[1].id or 0
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local name = player:getName()

	if slotMachineData.owner then
		player:sendCancelMessage('Wait your turn.')
		return true
	end

    -- Anti-Spam
    if player:getStorageValue(slotMachineData.EXHAUST_STORAGE) > os.time() then
        player:sendCancelMessage(RETURNVALUE_YOUAREEXHAUSTED)
        return true
    end

    local cost = slotMachineData.cost
    if not player:removeMoney(cost) then
        player:sendCancelMessage(('You don\'t have %d gold to play.'):format(cost))
        return true
    end

    slotMachineData.owner = name
    player:setStorageValue(slotMachineData.EXHAUST_STORAGE, os.time() + 2) -- 2 seconds delay

	item:transform(item.itemid + 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	fromPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	slotMachineData.positionEffectDice[1]:sendMagicEffect(CONST_ME_CRAPS)
	slotMachineData.positionEffectDice[2]:sendMagicEffect(CONST_ME_CRAPS)


	-- clear items
	for index, position in ipairs(positions) do
		local tile = Tile(position)
		if tile then
			local item = tile:getTopDownItem()
			if item then
				item:remove()
			end
		end

		addEvent(function()
			position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		end, index * 100)
	end

	local rolledTable = slotMachineData.rolled
	slotMachineData.rolled = {} -- Reset

	for index, position in ipairs(positions) do
		addEvent(function()
            local randomItem = getWeightedRandomItem(slotMachineData.items)
			local createdItem = Game.createItem(randomItem, 1, position)
			table.insert(slotMachineData.rolled, randomItem)

			position:sendMagicEffect(CONST_ME_FIREATTACK)
		end, index * 1000)
	end

	-- check the result
	addEvent(function(name)
		local win, rewardId = checkEquals(slotMachineData.rolled)
		local player = Player(name)
		if not player then
            if win then
                local resultId = db.storeQuery("SELECT `id` FROM `players` WHERE `name` = " .. db.escapeString(name))
                if not resultId then
                    return false
                end

                local targetPlayerGUID = result.getDataInt(resultId, "id")
                result.free(resultId)

                local targetPlayer = Player(targetPlayerGUID, true)
                if not targetPlayer then
                    return false
                end
                targetPlayer:getInbox():addItem(rewardId, 1)
                targetPlayer:save()
                targetPlayer:delete()
			end
		else
			if win then
                player:addItem(rewardId, 1)

                local rewardName = ItemType(rewardId):getName()
                player:sendTextMessage(MESSAGE_INFO_DESCR,
                    ('Congratulations, you won 1x %s.'):format(rewardName))
                Game.broadcastMessage(
                    ('[Slot Machine]: %s found 1x %s, how lucky.'):format(name, rewardName),
                    MESSAGE_EVENT_ADVANCE
                )
            end
		end

		item:transform(item.itemid - 1)
		slotMachineData.rolled = {}
		slotMachineData.owner = nil

		local centerPosition = positions[math.ceil(#positions/2)]
		if win then
			if doSendAnimatedText then
				doSendAnimatedText(centerPosition, 'WIN!', 30)
			end
			for _, position in ipairs(positions) do
				position:sendMagicEffect(CONST_ME_ENERGYAREA)
			end
			drawEffects()
		else
			if doSendAnimatedText then
				doSendAnimatedText(centerPosition, 'LOSE!', 180)
			end
			for _, position in ipairs(positions) do
				position:sendMagicEffect(CONST_ME_POFF)
			end
		end
	end, (#positions + 1) * 1000, name)
	return true
end
