-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

---------------------------------------------------------------
-- APPLY MODS TO CHAR
---------------------------------------------------------------

function addModificationToChar(rActor, vMod)
	if not rActor and not vMod then
		return;
	end

	local rData = vMod;
	if type(vMod) == "databasenode" then
		rData = CharModManager.getModificationData(vMod);
	end

	rData.sSummary = CharModManager.getCharacterModificationSummary(rData);

	if rData.sProperty == "stat" then
		CharModManager.applyStatModification(
			rActor, 
			rData);

	elseif rData.sProperty == "skill" then
	elseif rData.sProperty == "defense" then
	elseif rData.sProperty == "armor" then
	elseif rData.sProperty == "initiative" then
	elseif rData.sProperty == "ability" then
		CharModManager.applyAbilityModification(
			rActor,
			rData);

	elseif rData.sProperty == "recovery" then
	elseif rData.sProperty == "edge" then
	elseif rData.sProperty == "effort" then
	elseif rData.sProperty == "item" then
	elseif rData.sProperty == "cypherlimit" then
	end
end

function applyStatModification(rActor, rData)
	ActorManagerCypher.addToStatMax(rActor, rData.sStat, rData.nMod);

	rData.sSummary = "Stats: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applySkillModification(rActor, rData)
	rData.sSummary = "Skill: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyAbilityModification(rActor, rData)
	-- Add ability to list
	local charnode = ActorManager.getCreatureNode(rActor);
    local abilitylist = DB.createChild(charnode, "abilitylist");
    local abilitynode = DB.createChild(abilitylist);
	local sourcenode = DB.findNode(rData.sLinkRecord);

	if not (abilitynode or sourcenode) then
		return;
	end

    DB.copyNode(sourcenode, abilitynode);

	-- Save the ability name for later
	local sAbilityName = rData.sSummary or "";
	rData.sSummary = "Ability: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);

	for _, modnode in ipairs(DB.getChildList(sourcenode, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Ability)", sAbilityName);
		CharModManager.addModificationToChar(rActor, rMod);
	end
end

---------------------------------------------------------------
-- GET MOD DATA TABLE
---------------------------------------------------------------

function getModificationData(modNode)
	if not modNode then
		return;
	end
	
	local rMod = {};
	rMod.sProperty = DB.getValue(modNode, "property", "");

	if rMod.sProperty == "" then
		return;
	end

	-- Gets the parent object that contains this list of mods
	-- Currently this can be either abilities, descriptors, or ancestries
	local sourcenode = DB.getChild(modNode, "...")
	rMod.sSourceNode = DB.getPath(sourcenode)

	if rMod.sProperty == "Stat Pool" then
		rMod.sProperty = "stat"
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Skill" then
		rMod.sProperty = "skill"
		rMod.sSkill = DB.getValue(modNode, "skill", ""):lower();
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		rMod.sTraining = DB.getValue(modNode, "training", ""):lower();
		rMod.nAsset = DB.getValue(modNode, "asset", 0);
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Defense" then
		rMod.sProperty = "defense"
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		rMod.sTraining = DB.getValue(modNode, "training", ""):lower();
		rMod.nAsset = DB.getValue(modNode, "asset", 0);
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Armor" then
		rMod.sProperty = "armor"
		rMod.nMod = DB.getValue(modNode, "mod", 0);
		rMod.sDamageType = DB.getValue(modNode, "dmgtype", "");
		
	elseif rMod.sProperty == "Initiative" then
		rMod.sProperty = "initiative"
		rMod.sTraining = DB.getValue(modNode, "training", ""):lower();
		rMod.nAsset = DB.getValue(modNode, "asset", 0);
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Ability" then
		rMod.sProperty = "ability"
		rMod.sLinkClass, rMod.sLinkRecord = DB.getValue(modNode, "link");

	elseif rMod.sProperty == "Recovery" then
		rMod.sProperty = "recovery"
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Edge" then
		rMod.sProperty = "edge"
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Effort" then
		rMod.sProperty = "effort"
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Item" then
		rMod.sProperty = "item"
		rMod.sLinkClass, rMod.sLinkRecord = DB.getValue(modNode, "link");

	elseif rMod.sProperty == "Cypher Limit" then
		rMod.sProperty = "cypherlimit"
		rMod.nMod = DB.getValue(modNode, "mod", 0);
	end

	return rMod;
end

---------------------------------------------------------------
-- CHAR MOD SUMMARIES
---------------------------------------------------------------

function getCharacterModificationSummary(vMod)
	local rMod;
	if type(vMod) == "databasenode" then
		rMod = CharModManager.getModificationData(vMod);
	elseif type(vMod) == "table" then
		rMod = vMod;
	end
	
	if not rMod then
		return "";
	end

	if rMod.sProperty == "stat" then
		return CharModManager.getStatModSummary(rMod);
	elseif rMod.sProperty == "skill" then
		return CharModManager.getSkillModSummary(rMod);
	elseif rMod.sProperty == "defense" then
		return CharModManager.getDefenseModSummary(rMod);
	elseif rMod.sProperty == "armor" then
		return CharModManager.getArmorModSummary(rMod);
	elseif rMod.sProperty == "initiative" then
		return CharModManager.getInitiativeModSummary(rMod);
	elseif rMod.sProperty == "recovery" then
		return CharModManager.getRecoveryModSummary(rMod);
	elseif rMod.sProperty == "edge" then
		return CharModManager.getEdgeModSummary(rMod);
	elseif rMod.sProperty == "effort" then
		return CharModManager.getEffortModSummary(rMod);
	elseif rMod.sProperty == "cypherlimit" then
		return CharModManager.getCypherLimitModSummary(rMod);
	elseif rMod.sProperty == "ability" then
		return CharModManager.getAbilityModSummary(rMod);
	elseif rMod.sProperty == "item" then
		return CharModManager.getItemModSummary(rMod);
	end

	return "";
end

function getStatModSummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s to %s Pool",
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true),
		StringManager.capitalize(rMod.sStat or "")
	);
end

function getSkillModSummary(rMod)
	if not rMod then
		return "";
	end

	local sDisplay = CharModManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

	sDisplay = string.format("%s %s", 
		sDisplay, 
		rMod.sSkill)

	if (rMod.sStat or "" ~= "") then
		sDisplay = string.format("%s (%s)", 
			sDisplay, 
			rMod.sStat)
	end

	return sDisplay
end

function getDefenseModSummary(rMod)
	if not rMod then
		return "";
	end

	local sDisplay = CharModManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

	sDisplay = string.format("%s %s Defense rolls", 
		sDisplay, 
		StringManager.capitalize(rMod.sStat or ""))

	return sDisplay;
end

function getArmorModSummary(rMod)
	if not rMod then
		return "";
	end

	local sDmgType = "";
	if (rMod.sDamageType or "") ~= "" then
		sDmgType = string.format(" %s", rMod.sDamageType);
	end

	return string.format("%s%s Armor",
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true),
		sDmgType
	);
end

function getInitiativeModSummary(rMod)
	if not rMod then
		return "";
	end

	local sDisplay = CharModManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

	sDisplay = string.format("%s Initiative rolls", sDisplay)

	return sDisplay;
end

function getRecoveryModSummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s to Recovery rolls", 
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true)
	);
end

function getEdgeModSummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s %s Edge", 
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true),
		StringManager.capitalize(rMod.sStat or "")
	);
end

function getEffortModSummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s Effort", 
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true)
	);
end

function getCypherLimitModSummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s Cypher limit", 
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true)
	);
end

function getAbilityModSummary(rMod)
	if not rMod then
		return "";
	end

	local node = DB.findNode(rMod.sLinkRecord);
	return DB.getValue(node, "name", "");
end

function getItemModSummary(rMod)
	return CharModManager.getAbilityModSummary(rMod);
end

function getAssetModifierTrainingFormat(nAsset, nMod, sTraining)
	local sDisplay = "";
	local sAsset;
	local sMod;
	local sTrainingLine;
	local sPreposition = "";

	if (nAsset or 0) ~= 0 then
		sAsset = string.format("%s Asset", 
			DiceManager.convertDiceToString({}, nAsset, true)
		);	
		sPreposition = "for"
	end

	if (nMod or 0) ~= 0 then
		sMod = string.format("%s Modifier",
			DiceManager.convertDiceToString({}, nMod, true));

		sPreposition = "to"
	end

	if (sTraining or "") ~= "" then
		sTrainingLine = StringManager.capitalize(sTraining);
		sPreposition = "in"
	end

	if sAsset then
		sDisplay = sAsset
	end

	-- Add the correct joining charater between asset and mod
	if sAsset and sMod and sTrainingLine then
		sDisplay = string.format("%s, ", sDisplay)
	elseif (sAsset and sMod) or (sAsset and sTrainingLine) then
		sDisplay = string.format("%s and ", sDisplay)
	end

	if sMod then
		sDisplay = string.format("%s%s", sDisplay, sMod);
	end

	-- Add the correct joining charater between mod and training
	if sAsset and sMod and sTrainingLine then
		sDisplay = string.format("%s, and ", sDisplay)
	elseif sMod and sTrainingLine then
		sDisplay = string.format("%s and ", sDisplay)
	end

	if sTrainingLine then
		sDisplay = string.format("%s%s", sDisplay, sTrainingLine);
	end

	return string.format("%s %s", 
		sDisplay, 
		sPreposition);
end
