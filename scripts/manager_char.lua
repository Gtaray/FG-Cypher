-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
-------------------------------------------------------------------------------
-- Character class and statement functions
-------------------------------------------------------------------------------
function getCharacterStatement(nodeChar)
	if not nodeChar then
		return "";
	end

	local sAncestry = DB.getValue(nodeChar, "class.ancestry.name", "");
	local sDescriptor = DB.getValue(nodeChar, "class.descriptor.name", "");
	local sDescText = "";
	if sAncestry ~= "" and sDescriptor ~= "" then
		sDescText = string.format("%s %s", sDescriptor, sAncestry)
	elseif sAncestry ~= "" then
		sDescText = sAncestry
	elseif sDescriptor ~= "" then
		sDescText = sDescriptor
	end

	return string.format(
		Interface.getString("char_statement"), 
		DB.getValue(nodeChar, "name", ""),
		sDescText,
		DB.getValue(nodeChar, "class.type.name", ""),
		DB.getValue(nodeChar, "class.focus.name", ""))
end

-------------------------------------------------------------------------------
-- Character sheet drops
-------------------------------------------------------------------------------
function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "ability" then
		CharAbilityManager.addAbilityDrop(nodeChar, sClass, sRecord);
	elseif sClass == "type" then
		CharTypeManager.addTypeDrop(nodeChar, sClass, sRecord);
	elseif sClass == "descriptor" then
		CharDescriptorManager.addDescriptorDrop(nodeChar, sClass, sRecord);
	elseif sClass == "focus" then
		CharFocusManager.addFocusDrop(nodeChar, sClass, sRecord);
	elseif sClass == "ancestry" then
		CharAncestryManager.addAncestryDrop(nodeChar, sClass, sRecord);
	elseif sClass ==  "flavor" then
		CharFlavorManager.addFlavorDrop(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

function helperBuildAddStructure(nodeChar, sClass, sRecord)
	if not nodeChar or ((sClass or "") == "") or ((sRecord or "") == "") then
		return nil;
	end

	local rAdd = { };
	rAdd.nodeSource = DB.findNode(sRecord);
	if not rAdd.nodeSource then
		return nil;
	end

	rAdd.sSourceClass = sClass;
	rAdd.sSourceName = StringManager.trim(DB.getValue(rAdd.nodeSource, "name", ""));
	rAdd.nodeChar = nodeChar;
	rAdd.sCharName = StringManager.trim(DB.getValue(nodeChar, "name", ""));

	rAdd.sSourceType = StringManager.simplify(rAdd.sSourceName);
	if rAdd.sSourceType == "" then
		rAdd.sSourceType = DB.getName(rAdd.nodeSource);
	end

	return rAdd;
end

function getMaxAssets(rActor, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) then
		return 2;
	end

	return 2 + EffectManagerCypher.getMaxAssetsEffectBonus(rActor, aFilter);
end

function getMaxEffort(rActor, aFilter)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor or not ActorManager.isPC(rActor) then
		return 0;
	end

	local nBase = DB.getValue(nodeActor, "effort", 1);
	local nEffectMaxEffort = EffectManagerCypher.getMaxEffortEffectBonus(rActor, aFilter);
	
	-- clamp max effort to between 0 and 6
	return math.max(math.min(nBase + nEffectMaxEffort, 6), 1);
end

-------------------------------------------------------------------------------
-- HERO POINTS
-------------------------------------------------------------------------------
function getHeroPoints(nodeChar)
	return DB.getValue(nodeChar, "hero", 0)
end

function setHeroPoints(nodeChar, nVal)
	DB.setValue(nodeChar, "hero", "number", nVal)
end