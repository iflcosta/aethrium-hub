local config = {
	oldPosition = {
		[1] = Position(945, 1410, 8),
		[2] = Position(944, 1410, 8),
		[3] = Position(943, 1410, 8),
		[4] = Position(942, 1410, 8),
		[5] = Position(941, 1410, 8),
	},
	newPosition = {
		[1] = Position(943, 1429, 8),
		[2] = Position(942, 1429, 8),
		[3] = Position(941, 1429, 8),
		[4] = Position(940, 1429, 8),
		[5] = Position(939, 1429, 8),
	},
	monsterSpawn = {
		[1] = Position(940, 1426, 8),
		[2] = Position(942, 1426, 8),
		[3] = Position(944, 1426, 8),
		[4] = Position(939, 1432, 8),
		[5] = Position(941, 1432, 8),
		[6] = Position(943, 1432, 8),
		[7] = Position(944, 1429, 8),
		[8] = Position(945, 1429, 8),
	},
	monsterName = "Serpent Spawn",
	players = {},
	cooldownTime = 4, -- In hours
	storageCooldown = 86475,
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if Game.getStorageValue(config.storageCooldown) == -1 or not Game.getStorageValue(config.storageCooldown) then
		Game.setStorageValue(config.storageCooldown, 0)
	end

	if Game.getStorageValue(config.storageCooldown) >= os.time() then
		player:sendCancelMessage("Your team needs to wait ".. string.diff((Game.getStorageValue(config.storageCooldown) - os.time()), true) .. " to perform this quest.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if item.itemid == 1945 then
		for i = 1, #config.oldPosition do
			local topPlayer = Tile(config.oldPosition[i]):getTopCreature()
			if not topPlayer or not topPlayer:isPlayer() then
				player:sendCancelMessage("Your team needs at least ".. #config.oldPosition .. " players to perform this quest.")
				return true
			end
			config.players[#config.players + 1] = topPlayer
		end

		if #config.players < #config.oldPosition then
			player:sendCancelMessage("Your team needs at least ".. #config.oldPosition .. " players to perform this quest.")
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			for i = 1, #config.players do
				config.players[i] = nil
			end
			return true
		end

		for i, targetPlayer in ipairs(config.players) do
			Position(config.oldPosition[i]):sendMagicEffect(CONST_ME_POFF)
			targetPlayer:teleportTo(config.newPosition[i], false)
			targetPlayer:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end

		for v, c in ipairs(config.monsterSpawn) do
			Game.createMonster(config.monsterName, c, false, true)
			Position(config.monsterSpawn[v]):sendMagicEffect(CONST_ME_TELEPORT)
		end

		Game.setStorageValue(config.storageCooldown, os.time() + config.cooldownTime * 60 * 60)
		item:transform(1946)
		addEvent(function()
			local spectators = Game.getSpectators(Position(942, 1429, 8), false, false, 0, 4, 0, 4)
			if #spectators > 0 then
				for _, spectator in ipairs(spectators) do
					local creature = Creature(spectator)
					if creature:isMonster() then
						creature:remove()
					end
				end
			end
			item:transform(1945)
		end, 30 * 60 * 60 * 1000)

	elseif item.itemid == 1946 then
		player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
	end
	return true
end
