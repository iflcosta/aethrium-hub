local loginEvent = CreatureEvent("UpgradeSystemLogin")
loginEvent:type("login")

loginEvent:onLogin(function(player)
    player:registerEvent("UpgradeSystemCombat")
    player:registerEvent("UpgradeSystemManaCombat")
    player:registerEvent("UpgradeSystemUpdate") -- O novo evento de think
    
    -- Delay para garantir que todos os itens foram carregados e slots preenchidos
    addEvent(function(playerId)
        local p = Player(playerId)
        if p then UPGRADE_SYSTEM:recalculateStats(p) end
    end, 500, player:getId())
    
    return true
end)

loginEvent:register()

print("[Upgrade System] Eventos de combate Fase 1 registrados com sucesso!")
