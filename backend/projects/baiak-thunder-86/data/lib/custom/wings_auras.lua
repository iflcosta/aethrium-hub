-- Wings & Auras System Lib
-- Created for Baiak Thunder

if not WingsAura then
    WingsAura = {}
end

-- Protocolo OTCv8 para Shaders
WingsAura.OPCODE_WINGS = 150
WingsAura.OPCODE_AURA = 151
WingsAura.STORAGE_BASE = 55000

-- Configuração dos Itens Cosméticos
-- effect: ID do MagicEffect (fallback/clássico)
-- shader: Nome do arquivo .frag no cliente (moderno)
-- type: 1 para Wings (Opcode 150), 2 para Aura (Opcode 151)
WingsAura.items = {}

function WingsAura.showEffect(cid, itemId)
    local player = Player(cid)
    if not player then return false end
    
    local config = WingsAura.items[itemId]
    if not config then return false end
    
    -- Verifica se o item está equipado
    local itemNeck = player:getSlotItem(CONST_SLOT_NECKLACE)
    local itemRing = player:getSlotItem(CONST_SLOT_RING)
    
    local isEquipped = false
    if itemNeck and itemNeck:getId() == itemId then
        isEquipped = true
    elseif itemRing and itemRing:getId() == itemId then
        isEquipped = true
    end
    
    if isEquipped then
        -- 1. Envio de Shader (OTCv8 Moderno)
        if config.shader then
            local opcode = (config.type == 1) and WingsAura.OPCODE_WINGS or WingsAura.OPCODE_AURA
            player:sendExtendedOpcode(opcode, config.shader)
        end
    else
        -- Se não estiver equipado, desativa o shader no cliente
        if config.shader then
            local opcode = (config.type == 1) and WingsAura.OPCODE_WINGS or WingsAura.OPCODE_AURA
            player:sendExtendedOpcode(opcode, "none")
        end
    end

    return true
end
