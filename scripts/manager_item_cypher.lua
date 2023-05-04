function onInit()
	ItemManager.registerCleanupTransferHandler(onItemTransfer);
end

function onItemTransfer(rSource, rTemp, rTarget)
	-- Handle automatically rolling levels for cyphers
	if rSource.sType == "item" and (rTarget.sType == "treasureparcel" or rTarget.sType == "charsheet" or rTarget.sType == "partysheet") then
		ItemManagerCypher.generateCypherLevel(rTemp.node, false);
	end
end

function getItemType(itemNode)
	return DB.getValue(itemNode, "type", "");
end

function isItemCypher(itemNode)
	return ItemManagerCypher.getItemType(itemNode) == "cypher";
end

function generateCypherLevel(itemNode, bOverrideLevel)
	-- No matter what, we don't do this for non-cyphers
	if not ItemManagerCypher.isItemCypher(itemNode) then
		return 0;
	end

	-- Only set the level if nLevel is 0 OR if bOverrideLevel is true
	-- This tests the negative case of that
	local nLevel = DB.getValue(itemNode, "level", 0);
	if not bOverrideLevel and nLevel ~= 0 then
		return nLevel;
	end

	-- We can only roll the level if the levelroll value is actually a dice string
	local sLevelRoll = DB.getValue(itemNode, "levelroll", "");
	if not StringManager.isDiceString(sLevelRoll) then
		return nLevel;
	end

	nLevel = StringManager.evalDiceString(sLevelRoll, true);
	DB.setValue(itemNode, "level", "number", nLevel);

	return nLevel;
end