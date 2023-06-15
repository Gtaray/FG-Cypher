-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getCharacterModificationSummary(modNode)
	local rMod = CharModificationManager.getCharacterModificationData(modNode);
	if not rMod then
		return "";
	end

	if rMod.sProperty == "stat" then
		return CharModificationManager.getStatModSummary(rMod);
	elseif rMod.sProperty == "skill" then
		return CharModificationManager.getSkillModSummary(rMod);
	elseif rMod.sProperty == "defense" then
		return CharModificationManager.getDefenseModSummary(rMod);
	elseif rMod.sProperty == "armor" then
		return CharModificationManager.getArmorModSummary(rMod);
	elseif rMod.sProperty == "initiative" then
		return CharModificationManager.getInitiativeModSummary(rMod);
	elseif rMod.sProperty == "recovery" then
		return CharModificationManager.getRecoveryModSummary(rMod);
	elseif rMod.sProperty == "edge" then
		return CharModificationManager.getEdgeModSummary(rMod);
	elseif rMod.sProperty == "effort" then
		return CharModificationManager.getEffortModSummary(rMod);
	elseif rMod.sProperty == "cypherlimit" then
		return CharModificationManager.getCypherLimitModSummary(rMod);
	elseif rMod.sProperty == "ability" then
		return CharModificationManager.getAbilityModSummary(rMod);
	elseif rMod.sProperty == "item" then
		return CharModificationManager.getItemModSummary(rMod);
	end

	return "";
end

function getCharacterModificationData(modNode)
	if not modNode then
		return;
	end
	
	local rMod = {};
	rMod.sProperty = DB.getValue(modNode, "property", "");

	if rMod.sProperty == "" then
		return;
	end

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

	local sDisplay = CharModificationManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

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

	local sDisplay = CharModificationManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

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

	local sDisplay = CharModificationManager.getAssetModifierTrainingFormat(rMod.nAsset, rMod.nMod, rMod.sTraining);

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
	return CharModificationManager.getAbilityModSummary(rMod);
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