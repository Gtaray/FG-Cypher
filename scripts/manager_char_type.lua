-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addTypeDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Build the rest of the table that's specific to Types
	CharTypeManager.buildTier1AddTable(rAdd);

	if rAdd.nFloatingStats > 0 or #(rAdd.aEdgeOptions) > 0 or #(rAdd.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharTypeManager.applyTier1);
		return;
	end

	CharTypeManager.applyTier1(rAdd);
end

function getTypeNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.typelink");
	return DB.findNode(sRecord);
end

function characterHasType(nodeChar)
	return CharTypeManager.getTypeNode(nodeChar) ~= nil;
end

function getAbilitiesForCharacter(nodeChar, nTier)
	local nodeType = CharTypeManager.getTypeNode(nodeChar);
	return CharTypeManager.getAbilities(nodeType, nTier);
end

function buildTier1AddTable(rAdd)
	rAdd.nMight = DB.getValue(rAdd.nodeSource, "mightpool", 0);
	rAdd.nSpeed = DB.getValue(rAdd.nodeSource, "speedpool", 0);
	rAdd.nIntellect = DB.getValue(rAdd.nodeSource, "intellectpool", 0);
	rAdd.nFloatingStats = DB.getValue(rAdd.nodeSource, "floatingstats", 0);

	rAdd.nEffort = DB.getValue(rAdd.nodeSource, "effort", 0);
	rAdd.nCypherLimit = DB.getValue(rAdd.nodeSource, "cypherlimit", 0);

	rAdd.aEdgeGiven = {};
	rAdd.aEdgeOptions = {};
	for _, nodechoice in ipairs(DB.getChildList(rAdd.nodeSource, "edge")) do
		local sChoice = DB.getValue(nodechoice, "option", "");

		local aChoices = {};
		if sChoice ~= "" then
			if sChoice == Interface.getString("char_mod_edge_might")  then
				table.insert(rAdd.aEdgeGiven, "might");
			elseif sChoice == Interface.getString("char_mod_edge_speed") then
				table.insert(rAdd.aEdgeGiven, "speed");
			elseif sChoice == Interface.getString("char_mod_edge_intellect") then
				table.insert(rAdd.aEdgeGiven, "intellect");
			elseif sChoice == Interface.getString("char_mod_edge_might_or_speed") then
				table.insert(aChoices, "might");
				table.insert(aChoices, "speed");
			elseif sChoice == Interface.getString("char_mod_edge_might_or_intellect") then
				table.insert(aChoices, "might");
				table.insert(aChoices, "intellect");
			elseif sChoice == Interface.getString("char_mod_edge_speed_or_intellect") then
				table.insert(aChoices, "speed");
				table.insert(aChoices, "intellect");
			elseif sChoice == Interface.getString("char_mod_edge_any") then
				table.insert(aChoices, "might");
				table.insert(aChoices, "speed");
				table.insert(aChoices, "intellect");
			end
		end
		if #aChoices > 0 then
			table.insert(rAdd.aEdgeOptions, aChoices)
		end		
	end

	CharTypeManager.buildAbilityPromptTable(rAdd.nodeChar, rAdd.nodeSource, 1, rAdd);
end

function buildAbilityPromptTable(nodeChar, nodeType, nTier, rData)
	local sProperty = string.format("t%s_abilities", nTier)
	rData.nAbilityChoices = DB.getValue(nodeType, sProperty, 0);
	rData.aAbilitiesGiven = {};
	rData.aAbilityOptions = {};

	for _, nodeability in ipairs(DB.getChildList(nodeType, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == nTier then
			local _, sRecord = DB.getValue(nodeability, "link");
			if DB.getValue(nodeability, "given", 0) == 1 then
				table.insert(rData.aAbilitiesGiven, sRecord);
			else	
				table.insert(rData.aAbilityOptions, {
					nTier = nTier,
					sRecord = sRecord
				});
			end
		end
	end

	-- Add abilities from flavor (if it is present)
	CharFlavorManager.buildAbilityPromptTable(nodeChar, nTier, rData);
end

function applyTier1(rData)
	-- Notification
	CharManager.outputUserMessage("char_message_add_type", rData.sSourceName, rData.sCharName);

	CharTrackerManager.addToTracker(
		rData.nodeChar, 
		string.format("Type: %s", StringManager.capitalize(rData.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rData.nodeChar, "class.type", "string", rData.sSourceName);
	DB.setValue(rData.nodeChar, "class.typelink", "windowreference", rData.sSourceClass, DB.getPath(rData.nodeSource));

	CharTypeManager.addStartingEffort(rData);
	CharTypeManager.addStartingCypherLimit(rData);

	-- Set the character's starting stat pools
	CharTypeManager.setStartingPools(rData);

	-- Set edge
	CharTypeManager.setStartingEdge(rData);

	-- reset these properties, which we'll reuse when applying features
	rData.nFloatingStats = 0;
	rData.aEdgeGiven = nil;
	rData.aEdgeOptions = nil;

	-- Give starting abilities
	CharTypeManager.addAbilities(rData);
	CharFlavorManager.addAbilities(rData);

	rData.aAbilitiesGiven = nil;
	rData.aAbilityOptions = nil;

	-- Apply starting features
	for _, modnode in ipairs(DB.getChildList(rData.nodeSource, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Type)", StringManager.capitalize(rData.sSourceName));
		CharModManager.addModificationToChar(rData.nodeChar, rMod, rData);
	end

	if (rData.nFloatingStats or 0) > 0 or #(rData.aEdgeOptions or {}) > 0 then
		-- Prompt player for the data
		rData.sSource = string.format("%s (Type)", StringManager.capitalize(rData.sSourceName));
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rData, CharModManager.applyFloatingStatsAndEdge);
		return true;
	end

	return false;
end

function applyTier(rData)
	CharTypeManager.addAbilities(rData);
	CharFlavorManager.addAbilities(rData);
end

--------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------

function addStartingEffort(rData)
	DB.setValue(rData.nodeChar, "effort", "number", rData.nEffort or 1);

	local sSummary = string.format(
		"Effort: Set to %s", 
		rData.nEffort)
	local sSource = string.format("%s (Type)", StringManager.capitalize(rData.sSourceName));

	CharTrackerManager.addToTracker(nodeChar, sSummary, sSource);
end

function addStartingCypherLimit(rData)
	DB.setValue(rData.nodeChar, "cypherlimit", "number", rData.nCypherLimit or 1);

	local sSummary = string.format(
		"Cypher Limit: Set to %s", 
		rData.nCypherLimit)
	local sSource = string.format("%s (Type)", StringManager.capitalize(rData.sSourceName));

	CharTrackerManager.addToTracker(nodeChar, sSummary, sSource);
end

function setStartingPools(rData)
	if rData.nMight ~= 0 then
		CharTypeManager.setStartingStat(rData.nodeChar, "might", rData.nMight, rData.sSourceName);
	end
	if rData.nSpeed ~= 0 then
		CharTypeManager.setStartingStat(rData.nodeChar, "speed", rData.nSpeed, rData.sSourceName);
	end
	if rData.nIntellect ~= 0 then
		CharTypeManager.setStartingStat(rData.nodeChar, "intellect", rData.nIntellect, rData.sSourceName);
	end
end

function setStartingStat(nodeChar, sStat, nValue, sSource)
	ActorManagerCypher.setStatMax(nodeChar, sStat, nValue);

	local sSummary = string.format(
		"Stats: Set %s to %s", 
		StringManager.capitalize(sStat),
		nValue)
	sSource = string.format("%s (Type)", StringManager.capitalize(sSource));

	CharTrackerManager.addToTracker(nodeChar, sSummary, sSource);
end

function setStartingEdge(rData)
	local aEdge = {
		["might"] = 0,
		["speed"] = 0,
		["intellect"] = 0
	};

	for _, sStat in ipairs(rData.aEdgeGiven) do
		aEdge[sStat] = aEdge[sStat] + 1;
	end

	for sStat, nEdge in pairs(aEdge) do
		local sPath = string.format("abilities.%s.edge", sStat);
		DB.setValue(rData.nodeChar, sPath, "number", nEdge);

		if nEdge > 0 then
			CharTrackerManager.addToTracker(
				rData.nodeChar, 
				string.format("Edge: Set %s Edge to %s", StringManager.capitalize(sStat), nEdge),
				string.format("%s (Type)", StringManager.capitalize(rData.sSourceName)));
		end
	end
end

function addAbilities(rData)
	for _, sAbility in ipairs(rData.aAbilitiesGiven) do
		CharAbilityManager.addAbility(rData.nodeChar, sAbility, rData.sSourceName, "Type", rData);
	end
end