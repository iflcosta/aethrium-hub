if not json then dofile('data/lib/custom/json.lua') end
if not ModalWindow then dofile('data/lib/custom/modalwindow.lua') end
if not sendInitData then dofile('data/creaturescripts/scripts/custom/crafting_backend.lua') end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    --print(">> [Anvil] Triggered by " .. player:getName())
    
    if sendInitData then
        sendInitData(player)
    else
        --print(">> [Anvil] ERROR: sendInitData is still nil after dofile!")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Ocorreu um erro ao carregar o sistema de craft.")
    end
    
    return true
end