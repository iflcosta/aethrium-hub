-- Command to test all OTCv8 Cosmetics
-- Usage: !cosmetic ID (for wings/auras) or !cosmetic Name (for shaders)
-- Use !cosmetic none to clear

function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    if param == "" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Uso: !cosmetic ID ou !cosmetic Nome. Ex: !cosmetic 2 ou !cosmetic Outfit - Rainbow")
        return true
    end

    local opcode = 150 -- Usamos o 150 para testes gerais
    player:sendExtendedOpcode(opcode, param)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Enviado cosmético: " .. param)
    
    return true
end
