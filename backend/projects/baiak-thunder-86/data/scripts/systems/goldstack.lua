local upgradeCoins = {
    [2148] = {id = 2152, count = 100}, -- Gold -> Platinum
    [2152] = {id = 2160, count = 100}, -- Platinum -> Crystal
    [2160] = {id = 15515, count = 100}, -- Crystal -> Bar of Gold
}

local downgradeCoins = {
    [15515] = {id = 2160, count = 100}, -- Bar of Gold -> Crystal
    [2160] = {id = 2152, count = 100}, -- Crystal -> Platinum
    [2152] = {id = 2148, count = 100}, -- Platinum -> Gold
}

local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- 1. TENTA UPGRADE (Se tiver 100 moedas)
    local up = upgradeCoins[item.itemid]
    if up and item.type == 100 then
        item:remove(100)
        player:addItem(up.id, 1)
        fromPosition:sendMagicEffect(CONST_ME_GIFT_WRAPS)
        return true
    end

    -- 2. TENTA DOWNGRADE (Se tiver 1 moeda ou se clicar em um monte que não seja 100)
    local down = downgradeCoins[item.itemid]
    if down then
        -- Remove apenas 1 moeda da pilha atual
        item:remove(1)
        -- Adiciona 100 da moeda inferior
        player:addItem(down.id, 100)
        fromPosition:sendMagicEffect(CONST_ME_TELEPORT)
        return true
    end

    return false
end

-- Registra os IDs: Gold, Platinum, Crystal, Bar of Gold
action:id(2148, 2152, 2160, 15515)
action:register()