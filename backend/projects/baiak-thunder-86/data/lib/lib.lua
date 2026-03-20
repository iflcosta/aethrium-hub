-- Core API functions implemented in Lua
dofile('data/lib/core/core.lua')
dofile('data/lib/custom/json.lua')

-- Compatibility library for our old Lua API
dofile('data/lib/compat/compat.lua')	

-- Sistema de Upgrade de Itens
dofile('data/lib/custom/upgrade_system.lua')

-- Info Storage
dofile('data/lib/custom/infoStorage.lua')

-- Online Time System
dofile('data/lib/custom/onlineTime.lua')

-- Debug Lib
dofile('data/lib/custom/debug.lua')

-- Battlefield
dofile('data/lib/events/battlefield.lua')

-- Castle 24H
dofile('data/lib/events/castle.lua')

-- SafeZone
dofile('data/lib/events/safezone.lua')

-- SnowBall
dofile('data/lib/events/snowball.lua')

-- SuperUP
dofile('data/lib/custom/superup.lua')

-- Bosses
dofile('data/lib/events/bosses.lua')

-- FireStorm
dofile('data/lib/events/firestorm.lua')

-- Tasks
dofile('data/lib/custom/task.lua')

-- Reward Boss
dofile('data/lib/custom/rewardBoss.lua')

-- Premium Points
dofile('data/lib/custom/premiumPoints.lua')

-- Boost Creature
dofile('data/lib/custom/boostCreature.lua')

-- Monster Hunt
dofile('data/lib/custom/monsterHunt.lua')

-- Castle 48h
dofile('data/lib/events/castle48.lua')

-- Boss Room
dofile('data/lib/custom/bossRoom.lua')

-- Mining
dofile('data/lib/custom/mining.lua')

-- Guild Level
dofile('data/lib/custom/guildLevel.lua')

-- Snake Minigames
dofile('data/lib/minigames/snake.lua')

-- Modal Helper
dofile('data/lib/custom/modalwindow.lua')

-- Modal crafting
dofile('data/lib/custom/crafting.lua')

-- Item Absorb Lookup Table (auto-generated from items.xml)
dofile('data/lib/custom/item_absorb_table.lua')

-- Addon Modal
dofile('data/lib/modalhelper/addonModal.lua')

-- Task system + Daily Task System
dofile('data/lib/Task_system.lua')

-- BattlePass
dofile('data/lib/battlepass.lua')

-- Market System
dofile('data/lib/market.lua')

-- VIP System
dofile('data/scripts/systems/vip_system.lua')

-- Wings & Auras System
dofile('data/lib/custom/wings_auras.lua')

-- Potion System (Persistent)
dofile('data/lib/custom/potion_system.lua')

-- Titles System
dofile('data/lib/custom/titles_config.lua')
dofile('data/lib/custom/titles_lib.lua')
dofile('data/creaturescripts/scripts/custom/title_callback.lua')