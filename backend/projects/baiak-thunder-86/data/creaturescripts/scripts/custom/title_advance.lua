-- TITLES - Level Advance Check
function onAdvance(player, skill, oldLevel, newLevel)
    if skill == SKILL_LEVEL and newLevel >= 1000 then
        player:checkTitleUnlocks()
    end
    return true
end
