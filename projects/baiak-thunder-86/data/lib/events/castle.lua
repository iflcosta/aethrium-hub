CASTLE24H = {
	castleName = "[Castle 24H]", -- Prefix that will appear in messages
	messageNoGuild = "You are not part of any guild.", -- Message that will appear if the player is not in a guild
	messageGuildDominant = "The castle already belongs to your guild.", -- Message if the player tries to dominate the castle even though it belongs to their guild
	messageGuildNotDominant = "The castle does not belong to your guild.", -- If the castle does not belong to the player's guild
	messageMinimumLevel = "You do not have sufficient level to invade the castle.", -- If the player does not have the required level to enter
	messageWelcome = "Welcome to your castle.", -- Welcome message to the dominant guild
	levelRequiredToDominate = true, -- true to require level to dominate and false to not require
	level = 100, -- If levelRequiredToDominate is true, what is the required level?
	timeNotify = 10, -- Time in SECONDS to avoid spamming that the player is invading
}

function CASTLE24H:getGuildIdFromCastle()
  local guildId  = -1
  local resultId = db.storeQuery("SELECT `guild_id` FROM `castle`;")
  if (resultId ~= false) then
    guildId = result.getDataInt(resultId, "guild_id")
    result.free(resultId)
  end
  return guildId
end
