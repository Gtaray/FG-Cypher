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
	CharTypeManager.buildTypeTier1AddTable(nodeChar, rAdd);

	if rAdd.nFloatingStats > 0 or #(rAdd.aEdgeOptions) > 0 or #(rAdd.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_type", "");
		w.setData(rAdd, CharTypeManager.applyTier1);
		return;
	end

	CharTypeManager.applyTier1(nodeChar, rAdd);
end

function buildTypeTier1AddTable(nodeChar, rAdd)
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
				table.insert(aEdgeGiven, "might");
			elseif sChoice == Interface.getString("char_mod_edge_speed") then
				table.insert(aEdgeGiven, "speed");
			elseif sChoice == Interface.getString("char_mod_edge_intellect") then
				table.insert(aEdgeGiven, "intellect");
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

	rAdd.nAbilityChoices = DB.getValue(rAdd.nodeSource, "t1_abilities", 0);
	rAdd.aAbilitiesGiven = {};
	rAdd.aAbilityOptions = {};
	for _, nodeability in ipairs(DB.getChildList(rAdd.nodeSource, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == 1 then
			local sClass, sRecord = DB.getValue(nodeability, "link");
			if DB.getValue(nodeability, "given", 0) == 1 then
				table.insert(rAdd.aAbilitiesGiven, sRecord);
			else	
				table.insert(rAdd.aAbilityOptions, sRecord);
			end
		end
	end
end

function applyTier1(rAdd)
	-- Notification
	CharManager.outputUserMessage("char_message_add_type", rAdd.sSourceName, rAdd.sCharName);

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.type", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.typelink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));

	-- Set the character's starting stat pools
	-- CharTypeManager.setStartingPools(rAdd.nodeChar, rAdd.nodeSource);
end

function setStartingPools(nodeChar, nodeType)
	local nMight = DB.getValue(nodeType, "mightpool", 0);
	local nSpeed = DB.getValue(nodeType, "speedpool", 0);
	local nIntellect = DB.getValue(nodeType, "intellectpool", 0);

	if nMight ~= 0 then
		ActorManagerCypher.setStatMax(nodeChar, "might", nMight);
	end
	if nSpeed ~= 0 then
		ActorManagerCypher.setStatMax(nodeChar, "speed", nSpeed);
	end
	if nIntellect ~= 0 then
		ActorManagerCypher.setStatMax(nodeChar, "intellects", nIntellect);
	end
end