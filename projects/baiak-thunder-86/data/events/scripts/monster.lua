-- Function called when a monster's corpse is looted
function Monster:onDropLoot(corpse)
	local mType = self:getType()
    
    -- Check if the monster is a reward boss
	if mType:isRewardBoss() then
		corpse:registerReward()
		return
	end

    -- Check if loot rate is disabled
	if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
		return
	end

    -- Get the player who owns the corpse
	local player = Player(corpse:getCorpseOwner())
    
    -- Check if the player exists and has sufficient stamina
	if not player or player:getStamina() > 840 then
		local monsterLoot = mType:getLoot()

		-- Boost Loot
		player:checkLootPotion()
		local percentLoot = 0
		if player:getStorageValue(STORAGEVALUE_LOOT_TEMPO) > os.time() then
			local potion = lootPotion[player:getStorageValue(STORAGEVALUE_LOOT_ID)]
			if potion then
				percentLoot = potion.exp / 100
			end
		end

		-- VIP Boost
		local vipPercent = 0
		local tier = player:getStorageValue(50200) -- STORAGE_VIP_TIER
		if tier == 1 then
			vipPercent = 0.10 -- +10%
		elseif tier == 2 then
			vipPercent = 0.20 -- +20%
		elseif tier == 3 then
			vipPercent = 0.35 -- +35%
		end

		-- Apply loot boost to each item in the loot table
		for i = 1, #monsterLoot do
			monsterLoot[i].chance = monsterLoot[i].chance + (monsterLoot[i].chance * percentLoot) + (monsterLoot[i].chance * vipPercent)
			local item = corpse:createLootItem(monsterLoot[i])
			if not item then
				print(string.format('[Warning] DropLoot: Could not add loot item to corpse. [Monster: %s]', mType:getName()))
			end
		end

		-- Notify the player about the loot
		if player then
			local text = ("Loot de %s: %s"):format(mType:getNameDescription(), corpse:getContentDescription())
			local party = player:getParty()
			if party then
				party:broadcastPartyLoot(text)
			else
				if player:getStorageValue(STORAGEVALUE_LOOT) == 1 then
					sendChannelMessage(11, TALKTYPE_CHANNEL_O, text)
				else
					player:sendChannelMessage("", text, TALKTYPE_CHANNEL_R1, 11)
				end
			end
		end
	else
		-- Notify the player about low stamina
		local text = ("Loot de %s: nothing (due to low stamina)"):format(mType:getNameDescription())
		local party = player and player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			if player and player:getStorageValue(STORAGEVALUE_LOOT) == 1 then
				sendChannelMessage(11, TALKTYPE_CHANNEL_O, text)
			elseif player then
				player:sendChannelMessage("", text, TALKTYPE_CHANNEL_R1, 11)
			end
		end
	end

    -- Trigger the ONDROPLOOT event callback if available
	if hasEventCallback(EVENT_CALLBACK_ONDROPLOOT) then
		EventCallback(EVENT_CALLBACK_ONDROPLOOT, self, corpse)
	end
end

-- Function called when a monster spawns
function Monster:onSpawn(position, startup, artificial)
    -- Trigger the ONSPAWN event callback if available
	if hasEventCallback(EVENT_CALLBACK_ONSPAWN) then
		return EventCallback(EVENT_CALLBACK_ONSPAWN, self, position, startup, artificial)
	else
		return true
	end
end
