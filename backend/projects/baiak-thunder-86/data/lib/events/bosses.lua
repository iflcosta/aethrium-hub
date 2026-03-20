Bosses = {
	bosses = {
		["Merlin"] = {date = "02/26/24", time = 01, killTime = 1}, -- month/day/year - hour only - in hours
	},
	spawnBossPosition = Position(1646, 975, 9),
	teleportOpenPosition = Position(1003, 1217, 7),
	destinationPosition = Position(1646, 960, 8),
	level = {
		active = true,
		minimumLevel = 150,
	},
	teleportOpenTime = 20, -- In minutes
	messageOne = "[Boss] Thunder, lightning, and earthquakes in the depths of the continent... The magical portal is collapsing!",  -- 15 min
	messageTwo = "[Boss] There's no magic left to stop what's coming. The portal is fully open!", -- 10 min
	messageThree = "[Boss] Citizens, beware! An evil creature has just escaped from the portal.", -- 5 min
	messageTeleportClose = "[Boss] The teleport will close in 5 minutes and it won't be possible to enter the boss room anymore.",
	actionIdTeleport = 4247,
}

function Bosses:getBossName()
	for index, v in pairs(Bosses.bosses) do
		if v.date == os.date("%x") and v.time  == tonumber(os.date("%H")) then
			return index
		end
	end
	return nil
end

function Bosses:openTeleport()
	local tile = Tile(Bosses.teleportOpenPosition)
	if tile then
		local item = tile:getItemById(1387)
		if item then
			item:getPosition():sendMagicEffect(CONST_ME_POFF)
			item:remove()
		else
			local teleport = Game.createItem(1387, 1, Bosses.teleportOpenPosition)
			if teleport then
				teleport:setActionId(Bosses.actionIdTeleport)
			end
			addEvent(function()
				Bosses:openTeleport()
			end, Bosses.teleportOpenTime * 60 * 1000)
			addEvent(Game.broadcastMessage, (Bosses.teleportOpenTime - 5) * 60 * 1000, (Bosses.messageTeleportClose))
		end
	end
end

function Bosses:checkTime()
	for index, v in pairs(Bosses.bosses) do
		if v.date == os.date("%x") and v.time  == tonumber(os.date("%H")) then
			addEvent(function()
				local monster = Game.createMonster(index, Bosses.spawnBossPosition)
				monster:setEmblem(GUILDEMBLEM_ENEMY)
				local idMonster = monster:getId()
			end, 10 * 60 * 1000)
			addEvent(function()
				Bosses:removeMonster(idMonster)
			end, v.killTime * 60 * 60 * 1000)
			Bosses:sendMessages()
			Bosses:openTeleport()
		end
	end
end

function Bosses:sendMessages()
	Game.broadcastMessage(Bosses.messageOne)
	addEvent(Game.broadcastMessage, 5 * 60 * 1000, Bosses.messageTwo)
	addEvent(Game.broadcastMessage, 10 * 60 * 1000, Bosses.messageThree)
end

function Bosses:removeMonster(id)
	local monster = Monster(id)
	if monster then
		monster:getPosition():sendMagicEffect(CONST_ME_POFF)
		monster:remove()
	end
end
