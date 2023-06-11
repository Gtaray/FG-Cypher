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

	-- Now that the cypher has had a level generated, 
	-- we need to go through and adjust all actions
	CypherManager.applyCypherLevelToActions(itemNode);

	return nLevel;
end

-------------------------------------------------------------------------------
-- ACTION PROPERTY ADJUSTMENTS
-------------------------------------------------------------------------------
local tProperties = {
	["stat"] = { "training", "asset", "modifier", "cost" },
	["attack"] = { "training", "asset", "modifier", "cost" },
	["damage"] = { "damage", "damage type", "armor piercing", "cost" },
	["heal"] = { "healing", "cost" },
	["effect"] = { "duration", "effect text", "cost" },
}

-- This table maps the display text for the mod-able properties to their node name
-- in the DB. Any property not listed here already matches the DB source node name
local tPropertySources = {
	["damage type"] = "damagetype",
	["armor piercing"] = "pierceamount",
	["healing"] = "heal",
	["duration"] = "durmod",
	["effect text"] = "label"
}

local tPropertyTypes = {
	["training"] = "training",
	["asset"] = "number",
	["modifier"] = "number",
	["cost"] = "number",
	["damage"] = "number",
	["damage type"] = "string",
	["armor piercing"] = "number",
	["healing"] = "number",
	["duration"] = "number",
	["effect text"] = "string"
}

function getActionProperties(sActionType)
	return tProperties[sActionType];
end

function getPropertyType(sProperty)
	return tPropertyTypes[sProperty];
end

function getPropertySource(sProperty)
	if tPropertySources[sProperty] then
		return tPropertySources[sProperty];
	end

	return sProperty;
end

function applyCypherLevelToActions(nodeItem)
	for _, nodeAction in ipairs(DB.getChildList(nodeItem, "actions")) do
		CypherManager.applyCypherLevelToAction(nodeAction);
	end
end

function applyCypherLevelToAction(nodeAction)
	local rAdjustments = CypherManager.getAllAdjustmentsForAction(nodeAction);

	for i, rMod in ipairs(rAdjustments) do
		if CypherManager.shouldApplyModification(rMod) then
			CypherManager.applyModification(nodeAction, rMod);
			-- We're done here, delete the list of adjustments.
			DB.deleteChild(nodeAction, "adjustments");
		end
	end
end

function shouldApplyModification(rMod)
	-- If the threshold type isn't set, return true
	if rMod.sThresholdType == "" then
		return true;
	end

	if rMod.sThresholdType == "equal to" then
		return rMod.nCypherLevel == rMod.nThreshold;
	elseif rMod.sThresholdType == "greater than" then
		return  rMod.nCypherLevel > rMod.nThreshold;
	elseif rMod.sThresholdType == "less than" then
		return  rMod.nCypherLevel < rMod.nThreshold;
	elseif rMod.sThresholdType == "at least" then
		return  rMod.nCypherLevel >= rMod.nThreshold;
	elseif rMod.sThresholdType == "at most" then
		return  rMod.nCypherLevel <= rMod.nThreshold;
	end

	return true;
end

function applyModification(nodeAction, rMod)
	if (rMod.sProperty or "") == "" then
		return;
	end

	-- Apply any specified operation
	if rMod.sPropertyType == "number" then
		if rMod.sOperation == "plus" then
			rMod.vValue = rMod.vValue + rMod.nOperand
		elseif rMod.sOperation == "minus" then
			rMod.vValue = rMod.vValue - rMod.nOperand
		elseif rMod.sOperation == "multiplied by" then
			rMod.vValue = rMod.vValue * rMod.nOperand
		elseif rMod.sOperation == "divided by" then
			rMod.vValue = math.floor(rMod.vValue / rMod.nOperand);
		end
	end

	DB.setValue(nodeAction, rMod.sProperty, rMod.sPropertyType, rMod.vValue)

	-- Extra bits that need to be handled
	if rMod.sProperty == "pierceamount" then
		DB.setValue(nodeAction, "pierce", "string", "yes");
	end
	if rMod.sProperty == "cost" then
		DB.setValue(nodeAction, "costtype", "string", "fixed");
	end
end

function getAllAdjustmentsForAction(nodeAction)
	rAdjustments = {};

	for _, nodeAdjust in ipairs(DB.getChildList(nodeAction, "adjustments")) do
		local rModification = CypherManager.buildModificationTable(nodeAdjust);

		if rModification then
			rAdjustments[rModification.nOrder] = rModification;
		end
	end

	return rAdjustments;
end

-- Builds a table representing a single modification rule for an action
function buildModificationTable(nodeMod)
	local rMod = {};

	rMod.sProperty = DB.getValue(nodeMod, "property", "");
	if (rMod.sProperty or "") == "" then
		return;
	end

	rMod.sPropertyType = CypherManager.getPropertyType(rMod.sProperty);
	if (rMod.sPropertyType or "") == "" then
		return;
	end

	-- align property and property type to their DB-related values
	-- We do this after getting property type because that's how the tables are set up
	rMod.sProperty = CypherManager.getPropertySource(rMod.sProperty);

	rMod.nCypherLevel = DB.getValue(nodeMod, ".....level", 0);

	-- Don't process if the cypher level is 0
	if rMod.nCypherLevel <= 0 then
		return;
	end

	if rMod.sPropertyType == "number" then
		if DB.getValue(nodeMod, "valuesource", "") == "cypher level" then
			rMod.vValue = rMod.nCypherLevel;
		else
			rMod.vValue = DB.getValue(nodeMod, "value_number", 0);	
		end

		rMod.sOperation = DB.getValue(nodeMod, "operation", "");
		if DB.getValue(nodeMod, "operationsource", "") == "cypher level" then
			rMod.nOperand = rMod.nCypherLevel;
		else
			rMod.nOperand = DB.getValue(nodeMod, "operand", 0);
		end
	elseif rMod.sPropertyType == "string" then
		rMod.vValue = DB.getValue(nodeMod, "value_string", "");
	elseif rMod.sPropertyType == "training" then
		rMod.vValue = DB.getValue(nodeMod, "value_training", "");
		rMod.sPropertyType = "string"; -- Change the property, because at this point it's just a string
	end

	rMod.sThresholdType = DB.getValue(nodeMod, "thresholdtype", "");
	rMod.nThreshold = DB.getValue(nodeMod, "threshold", "");

	rMod.nOrder = DB.getValue(nodeMod, "order", 0);

	return rMod;
end