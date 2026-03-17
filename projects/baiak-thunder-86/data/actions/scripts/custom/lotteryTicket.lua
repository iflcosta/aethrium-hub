local presents = {
	[5957] = {
		{2160, 10}, 12544, 8978, 11421, 7477, 10089, 10760, 8205
	}
}

local LOTTERY_EXHAUST = 50901

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- Anti-Spam
	if player:getStorageValue(LOTTERY_EXHAUST) > os.time() then
		return true
	end

	local targetItem = presents[item.itemid]
	if not targetItem then
		return true
	end

	-- Remove item first to prevent race conditions
	if not item:remove(1) then
		return true
	end

	local gift = targetItem[math.random(#targetItem)]
	local itemID = gift
	local count = 1
	if type(gift) == "table" then
		itemID = gift[1]
		count = gift[2]
	end

	player:addItem(itemID, count)
	player:setStorageValue(LOTTERY_EXHAUST, os.time() + 1)
	player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	return true
end
