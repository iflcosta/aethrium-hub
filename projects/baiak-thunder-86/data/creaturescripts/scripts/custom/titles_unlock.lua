-- ============================================================
-- TITLES SYSTEM - Automatic Unlock Triggers
-- Formato antigo (creaturescripts/) - sem CreatureEvent() API
-- ============================================================

function onLogin(player)
    player:checkTitleUnlocks()
    return true
end
