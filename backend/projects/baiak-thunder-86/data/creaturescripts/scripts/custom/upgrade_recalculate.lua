function onThink(player, interval)
    -- Throttling: Verificar a cada 2 segundos (2000ms)
    -- O 'interval' do think costuma ser 1000ms, mas varia de acordo com o config.lua
    -- Usaremos storage para controle fino de tempo
    local lastCheck = player:getStorageValue(50505) or 0
    local now = os.time()
    
    if lastCheck > now then
        return true
    end
    
    -- Configurar próxima checagem para daqui a 2 segundos
    player:setStorageValue(50505, now + 2)
    
    -- Comparar checksum simples de itens nos slots principais para evitar recálculo pesado se nada mudou
    -- Slots: head, armor, legs, feet, left, right, necklace, ring, ammo
    local checksum = 0
    for i = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
        local item = player:getSlotItem(i)
        if item then
            checksum = checksum + item:getId() + (item:getCustomAttribute("upgradeTier") or 0)
        end
    end
    
    local lastChecksum = player:getStorageValue(50506) or 0
    if checksum == lastChecksum then
        return true
    end
    
    -- Mudança detectada! Recalcular.
    player:setStorageValue(50506, checksum)
    UPGRADE_SYSTEM:recalculateStats(player)
    
    return true
end
