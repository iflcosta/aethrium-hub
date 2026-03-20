GMFullLightOnEquipItem = true
closedWorld = false
showMonsterExiva = true
antiBot = true
guildLeaderSquare = true
pvpBalance = true
pushCruzado = true

monsterBonusHealth = 0.5
monsterBonusSpeed = 0.02
monsterBonusDamage = 0.02



accountManager = false
namelockManager = false
newPlayerChooseVoc = true
newPlayerSpawnPosX = 121
newPlayerSpawnPosY = 311
newPlayerSpawnPosZ = 7
newPlayerTownId = 1
newPlayerLevel = 8
newPlayerMagicLevel = 0
generateAccountNumber = false
generateAccountSalt = false



worldType = "pvp"
hotkeyAimbotEnabled = true
protectionLevel = 50
killsToRedSkull = 100
killsToBlackSkull = 150
pzLocked = 30000
removeChargesFromRunes = true
removeChargesFromPotions = true
removeWeaponAmmunition = true
removeWeaponCharges = true
timeToDecreaseFrags = 24 * 60 * 60 * 1000
whiteSkullTime = 30 * 1000
stairJumpExhaustion = 1000
experienceByKillingPlayers = false
expFromPlayersLevelRange = 100

spoofEnabled = false
spoofDailyMinPlayers = 1
spoofDailyMaxPlayers = 2050
spoofNoiseInterval = 1000
spoofNoise = 0
spoofTimezone = -1
spoofInterval = 1
spoofChangeChance = 70
spoofIncrementChange = 100

ip = "127.0.0.1"
bindOnlyGlobalAddress = false
loginProtocolPort = 7171
gameProtocolPort = 7172
statusProtocolPort = 7171
maxPlayers = 1900
motd = "Bem-vindo ao Baiak Thunder!"
onePlayerOnlinePerAccount = true
allowClones = false
allowWalkthrough = true
serverName = "Baiak Thunder"
statusTimeout = 5000
replaceKickOnLogin = true
maxPacketsPerSecond = 475
packetCompression = true

deathLosePercent = -1

housePriceEachSQM = 1000
houseRentPeriod = "weekly"

timeBetweenActions = 200
timeBetweenExActions = 100

mapName = "real02"
mapAuthor = "Felipe"

marketOfferDuration = 30 * 24 * 60 * 60
premiumToCreateMarketOffer = true
checkExpiredMarketOffersEachMinutes = 60
maxMarketOffersAtATimePerPlayer = 100

-- MySQL
mysqlHost = "127.0.0.1"
mysqlUser = "root"
mysqlPass = "6652827"
mysqlDatabase = "forgotten"
mysqlPort = 3306
mysqlSock = ""

allowChangeOutfit = true
freePremium = true
kickIdlePlayerAfterMinutes = 15
maxMessageBuffer = 4
emoteSpells = true
classicEquipmentSlots = false
classicAttackSpeed = true
showScriptsLogInConsole = false
showOnlineStatusInCharlist = false

serverSaveNotifyMessage = true
serverSaveNotifyDuration = 5
serverSaveCleanMap = false
serverSaveClose = false
serverSaveShutdown = true

experienceStages = {
	{ minlevel = 1, maxlevel = 100, multiplier = 400 },
	{ minlevel = 101, maxlevel = 200, multiplier = 300 },
	{ minlevel = 201, maxlevel = 250, multiplier = 150 },
	{ minlevel = 251, maxlevel = 300, multiplier = 75 },
	{ minlevel = 301, maxlevel = 400, multiplier = 35 },
	{ minlevel = 401, maxlevel = 450, multiplier = 20 },
	{ minlevel = 451, maxlevel = 500, multiplier = 15 },
	{ minlevel = 501, maxlevel = 600, multiplier = 10 },
	{ minlevel = 601, multiplier = 5 },
}

rateSkill = 5
rateLoot = 3
rateMagic = 5
rateSpawn = 2
spawnMultiplier = 1

-- removeOnDespawn will remove the monster if true or teleport it back to its spawn position if false
deSpawnRange = 2
deSpawnRadius = 25
removeOnDespawn = false

staminaSystem = true

warnUnsafeScripts = true
convertUnsafeScripts = true

defaultPriority = "high"
startupDatabaseOptimization = false

ownerName = "Iago Lopes"
ownerEmail = "iflopes@outlook.com"
url = ""
location = "Brazil"
