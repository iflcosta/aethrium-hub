-- !rank - Show Task Rank of yourself or another player
function onSay(player, words, param)
    local target = player
    if param and param ~= "" then
        target = Player(param)
        if not target then
            player:sendCancelMessage("Player '" .. param .. "' not found or offline.")
            return false
        end
    end

    local points = taskPoints_get(target)
    local rank   = getRankTask(target)

    local msg = string.format(
        "- Task Rank: %s -\nPlayer: %s\nTask Points: %d",
        rank, target:getName(), points
    )
    player:sendTextMessage(MESSAGE_INFO_DESCR, msg)
    return false
end
