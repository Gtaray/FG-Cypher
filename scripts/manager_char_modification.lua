-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

---------------------------------------------------------------
-- APPLY MODS TO CHAR
---------------------------------------------------------------

function addModificationToChar(rActor, vMod)
	if type(rActor) == "databasenode" then
		rActor = ActorManager.resolveActor(rActor);
	end
	if not rActor and not vMod then
		return;
	end

	local rData = vMod;
	if type(vMod) == "databasenode" then
		rData = CharModManager.getModificationData(vMod);
	end

	rData.sSummary = CharModManager.getCharacterModificationSummary(rData);

	if rData.sProperty == "stat" then
		CharModManager.applyStatModification(rActor, rData);

	elseif rData.sProperty == "skill" then
		CharModManager.applySkillModification(rActor, rData);

	elseif rData.sProperty == "defense" then
		CharModManager.applyDefenseModification(rActor, rData);

	elseif rData.sProperty == "armor" then
		CharModManager.applyArmorModification(rActor, rData);

	elseif rData.sProperty == "initiative" then
		CharModManager.applyInitiativeModification(rActor, rData);

	elseif rData.sProperty == "ability" then
		CharModManager.applyAbilityModification(rActor, rData);

	elseif rData.sProperty == "recovery" then
		CharModManager.applyRecoveryModification(rActor, rData);

	elseif rData.sProperty == "edge" then
		CharModManager.applyEdgeModification(rActor, rData);

	elseif rData.sProperty == "effort" then
		CharModManager.applyEffortModification(rActor, rData);

	elseif rData.sProperty == "item" then
		CharModManager.applyItemModification(rActor, rData);

	elseif rData.sProperty == "cypherlimit" then
		CharModManager.applyCypherLimitModification(rActor, rData);
	end
end

function applyStatModification(rActor, rData)
	if rData.sStat == "flex" then
		local w = Interface.openWindow("select_dialog_stats", "");
		local rDialog = {
			nodeChar = ActorManager.getCreatureNode(rActor),
			nMight = ActorManagerCypher.getStatPool(rActor, "might"),
			nSpeed = ActorManagerCypher.getStatPool(rActor, "speed");
			nIntellect = ActorManagerCypher.getStatPool(rActor, "intellect");
			nFloatingStats = rData.nMod,
			sSource = rData.sSource
		};
		w.setData(rDialog, CharModManager.applyFloatingStatModificationCallback);
		return;
	end

	ActorManagerCypher.addToStatMax(rActor, rData.sStat, rData.nMod);

	rData.sSummary = "Stats: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyFloatingStatModificationCallback(rData)
	local rActor = ActorManager.resolveActor(rData.nodeChar);
	local nCurMight = ActorManagerCypher.getStatPool(rActor, "might");
	local nCurSpeed = ActorManagerCypher.getStatPool(rActor, "speed");
	local nCurIntellect = ActorManagerCypher.getStatPool(rActor, "intellect");

	if nCurMight ~= rData.nMight then
		local nMod = rData.nMight - nCurMight;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "might",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "might", nMod = nMod }),
			sSource = rData.sSource
		});
	end
	if nCurSpeed ~= rData.nSpeed then
		local nMod = rData.nSpeed - nCurSpeed;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "speed",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "speed", nMod = nMod }),
			sSource = rData.sSource
		});
	end
	if nCurIntellect ~= rData.nIntellect then
		local nMod = rData.nIntellect - nCurIntellect;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "intellect",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "intellect", nMod = nMod }),
			sSource = rData.sSource
		});
	end
end

function applySkillModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);
	local skilllist = DB.createChild(charnode, "skilllist");
	local sSkill = StringManager.trim(rData.sSkill or ""):lower();
	local matchnode;
	for _, skillnode in ipairs(DB.getChildList(skilllist)) do
		local sCurSkill = StringManager.trim(DB.getValue(skillnode, "name", "")):lower();

		if sSkill == sCurSkill then
			matchnode = skillnode;
			break;
		end
	end

	-- If there's no matched skill in the list, then we create one
	if not matchnode then
		matchnode = DB.createChild(skilllist);
		DB.setValue(matchnode, "name", "string", rData.sSkill);
	end

	-- Only change the stat if the skill doesn't have a stat set
	if (rData.sStat or "") ~= "" and DB.getValue(matchnode, "stat", "") == "" then
		DB.setValue(matchnode, "stat", "string", rData.sStat);
	end
	
	CharModManager.applyModToTrainingNode(matchnode, "training", rData.sTraining);
	CharModManager.applyModToAssetNode(matchnode, "asset", rData.nAsset);
	CharModManager.applyModToModifierNode(matchnode, "misc", rData.nMod);

	rData.sSummary = "Skill: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyDefenseModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);
	local sPath = "abilities." .. rData.sStat;
	local statnode = DB.getChild(charnode, sPath)
	if not statnode then
		return;
	end



	CharModManager.applyModToTrainingNode(defnode, "training", rData.sTraining);
	CharModManager.applyModToAssetNode(defnode, "asset", rData.nAsset);
	CharModManager.applyModToModifierNode(defnode, "misc", rData.nMod);

	rData.sSummary = "Defense: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyArmorModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);
	local resistances = DB.getChild(charnode, "resistances");
	local sDmgType = StringManager.trim(rData.sDamageType or ""):lower();

	rData.sSummary = "Armor: " .. rData.sSummary;

	-- First we handle the case where the damage type is empty
	-- thus we place the armor in the character's Armor node
	if (sDmgType or "") == "" then
		nCurArmor = DB.getValue(charnode, "armor", 0);
		DB.setValue(charnode, "armor", "number", nCurArmor + rData.nMod);

		CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
		return;
	end

	-- Now we handle the case where there is a damage type, and thus
	-- it should go in the resistances list
	local matchnode;
	for _, resistnode in ipairs(DB.getChildList(resistances)) do
		local sCurDmgType = StringManager.trim(DB.getValue(resistnode, "damagetype", "")):lower();

		if sDmgType == sCurDmgType then
			matchnode = resistnode;
			break;
		end
	end

	-- If there's no matched armor type in the list, then we create one
	if not matchnode then
		matchnode = DB.createChild(resistances);
		DB.setValue(matchnode, "damagetype", "string", rData.sDamageType);
	end

	-- if the given value is 0, then overwrite any other value 
	-- because 0 means immunity
	if rData.nMod == 0 then
		DB.setValue(matchnode, "armor", "number", 0);

		rData.sSummary = rData.sSummary .. " (Immunity)";
		CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
		return;
	end

	-- There's some tricky bits here becasue an armor value of 0 means immunity
	-- which means that if modified amount totals to 0, we need to delete
	-- the matched node
	-- And if the value in rData.nMod is 0, it needs to overwrite any other value
	local nNewValue = CharModManager.applyModToModifierNode(matchnode, "armor", rData.nMod);

	-- If, after modification, the armor value is set to 0, then we need
	-- to delete it so that it isn't treated as an immunity
	if nNewValue == 0 then
		DB.deleteNode(matchnode);
		rData.sSummary = rData.sSummary .. " (Removed)";
	end

	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyInitiativeModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharModManager.applyModToTrainingNode(charnode, "inittraining", rData.sTraining);
	CharModManager.applyModToAssetNode(charnode, "initasset", rData.nAsset);
	CharModManager.applyModToModifierNode(charnode, "initmod", rData.nMod);

	rData.sSummary = "Initiative: " .. rData.sSummary;
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

function applyRecoveryModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharModManager.applyModToModifierNode(charnode, "recoveryrollmod", rData.nMod);

	rData.sSummary = "Recovery: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyEdgeModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);
	local sPath = "abilities." .. rData.sStat;
	local statnode = DB.getChild(charnode, sPath)
	if not statnode then
		return;
	end

	CharModManager.applyModToModifierNode(statnode, "edge", rData.nMod);

	rData.sSummary = "Edge: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyEffortModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharModManager.applyModToModifierNode(charnode, "effort", rData.nMod);

	rData.sSummary = "Effort: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyItemModification(rActor, rData)
	-- Add ability to list
	local charnode = ActorManager.getCreatureNode(rActor);
	local sourcenode = DB.findNode(rData.sLinkRecord);

	if not sourcenode then
		return;
	end

	ItemManager.handleItem(charnode, nil, "item", rData.sLinkRecord, true);

	rData.sSummary = "Item: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyCypherLimitModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharModManager.applyModToModifierNode(charnode, "cypherlimit", rData.nMod);

	rData.sSummary = "Cypher Limit: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

-- 0 = inability, 1 - nothing, 2 = trained, 3 = specialized
function applyModToTrainingNode(node, sPath, sTraining)
	if (sTraining or "") == "" then
		return;
	end

	local nCurTraining = DB.getValue(node, sPath, 1);
	nCurTraining = nCurTraining + RollManager.processTraining(
		sTraining == "inability",
		sTraining == "trained",
		sTraining == "specialized"
	)

	-- Clamp training between 0 and 3
	nCurTraining = math.min(math.max(nCurTraining, 0), 3);
	DB.setValue(node, sPath, "number", nCurTraining);
end
function applyModToAssetNode(node, sPath, nAsset)
	if (nAsset or 0) == 0 then
		return;
	end

	nAsset = DB.getValue(node, sPath, 0) + nAsset;
	DB.setValue(node, sPath, "number", nAsset);
end
function applyModToModifierNode(node, sPath, nMod)
	if (nMod or 0) == 0 then
		return;
	end

	nMod = DB.getValue(node, sPath, 0) + nMod;
	DB.setValue(node, sPath, "number", nMod);
	return nMod;
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
		rMod.sSkill = DB.getValue(modNode, "skill", "");
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

	local sStatPool = string.format("%s Pool", StringManager.capitalize(rMod.sStat or ""));
	if rMod.sStat == "flex" then
		sStatPool = "divide among your stat pools"
	end

	return string.format("%s to %s",
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true),
		sStatPool
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
