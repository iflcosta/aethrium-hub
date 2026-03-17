--[[
    BATTLEPASS KILL TRACKER - Styller Nexus
    Rastreia kills de monstros para BattlePass
    [DISABLED] - Battlepass was refactored to use Global XP (Storage 30050)
]]

local battlepassKill = CreatureEvent("BattlePassKill")

function battlepassKill.onKill(player, target)
    return true
end

battlepassKill:register()
