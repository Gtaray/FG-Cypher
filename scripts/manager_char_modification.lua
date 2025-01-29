-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

---------------------------------------------------------------
-- APPLY MODS TO CHAR
---------------------------------------------------------------
function addModificationToChar(rActor, vMod, rPromptData)
	if type(rActor) == "databasenode" then
		rActor = ActorManager.resolveActor(rActor);
	end
	if not rActor and not vMod then
		return;
	end

	if not rPromptData then
		rPromptData = {};
	end

	local rData = vMod;
	if type(vMod) == "databasenode" then
		rData = CharModManager.getModificationData(vMod);
	end

	rData.sSummary = CharModManager.getCharacterModificationSummary(rData);

	if rData.sProperty == "stat" then
		if rData.sStat == "flex" then
			-- Add any flex stats to the prmopt table to prompt the player to select
			-- when everything is done
			rPromptData.nFloatingStats = (rPromptData.nFloatingStats or 0) + rData.nMod;
		else
			CharModManager.applyStatModification(rActor, rData);
		end

	elseif rData.sProperty == "skill" then
		CharModManager.applySkillModification(rActor, rData);

	elseif rData.sProperty == "defense" then
		CharModManager.applyDefenseModification(rActor, rData);

	elseif rData.sProperty == "armor" then
		CharModManager.applyArmorModification(rActor, rData);

	elseif rData.sProperty == "initiative" then
		CharModManager.applyInitiativeModification(rActor, rData);

	elseif rData.sProperty == "ability" then
		CharModManager.applyAbilityModification(rActor, rData, rPromptData);

	elseif rData.sProperty == "recovery" then
		CharModManager.applyRecoveryModification(rActor, rData);

	elseif rData.sProperty == "edge" then
		if rData.sStat == "flex" then
			if not rPromptData.aEdgeOptions then
				rPromptData.aEdgeOptions = {}
			end
			-- Add flex edge to the prompt table for later prompting
			table.insert(rPromptData.aEdgeOptions, { "might", "speed", "intellect" });
		else
			CharModManager.applyEdgeModification(rActor, rData);
		end

	elseif rData.sProperty == "effort" then
		CharModManager.applyEffortModification(rActor, rData);

	elseif rData.sProperty == "item" then
		CharModManager.applyItemModification(rActor, rData);

	elseif rData.sProperty == "cypherlimit" then
		CharModManager.applyCypherLimitModification(rActor, rData);

	elseif rData.sProperty == "armoreffortpenalty" then
		CharModManager.applyArmorEffortPenaltyModification(rActor, rData);
		
	end

	-- This is really only used for when an ability is dropped onto a PC
	-- descriptor/ancestries handle mod prompting using the table directly
	return rPromptData;
end

function applyFloatingStatsAndEdge(rData)
	local rActor = ActorManager.resolveActor(rData.nodeChar);
	local nCurMight, nMaxMight = CharStatManager.getStatPool(rActor, "might");
	local nCurSpeed, nMaxSpeed = CharStatManager.getStatPool(rActor, "speed");
	local nCurIntellect, nMaxIntellect = CharStatManager.getStatPool(rActor, "intellect");

	if nMaxMight ~= rData.nMight then
		local nMod = rData.nMight - nMaxMight;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "might",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "might", nMod = nMod }),
			sSource = rData.sSource
		});
	end
	if nMaxSpeed ~= rData.nSpeed then
		local nMod = rData.nSpeed - nMaxSpeed;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "speed",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "speed", nMod = nMod }),
			sSource = rData.sSource
		});
	end
	if nMaxIntellect ~= rData.nIntellect then
		local nMod = rData.nIntellect - nMaxIntellect;
		CharModManager.applyStatModification(rActor, {
			sProperty = "stat",
			sStat = "intellect",
			nMod = nMod,
			sSummary = CharModManager.getStatModSummary({ sStat = "intellect", nMod = nMod }),
			sSource = rData.sSource
		});
	end

	local aEdge = {
		["might"] = 0,
		["speed"] = 0,
		["intellect"] = 0
	};

	for _, sStat in ipairs(rData.aEdgeGiven or {}) do
		aEdge[sStat] = aEdge[sStat] + 1;
	end

	for sStat, nEdge in pairs(aEdge) do
		if nEdge > 0 then
			local rEdge = {
				sProperty = "edge",
				sStat = sStat,
				nMod = nEdge,
				sSource = rData.sSource,
			}
			rEdge.sSummary = CharModManager.getEdgeModSummary(rEdge);

			CharModManager.applyEdgeModification(rActor, rEdge)
		end
	end
end

function applyStatModification(rActor, rData)
	-- If this is a custom stat, then create the pool if it doesn't exist.
	if not StringManager.contains({ "might", "speed", "intellect" }, rData.sStat) then
		if not CharStatManager.hasCustomStatPool(rActor, rData.sStat) then
			CharStatManager.createCustomStatPool(rActor, rData.sStat);
		end
	end

	ActorStatManager.modifyStatMax(rActor, rData.sStat, rData.nMod);

	rData.sSummary = "Stats: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applySkillModification(rActor, rData)
	-- If this is a custom stat, then create the pool if it doesn't exist.
	if not StringManager.contains({ "might", "speed", "intellect" }, rData.sStat) then
		if not CharStatManager.hasCustomStatPool(rActor, rData.sStat) then
			CharStatManager.createCustomStatPool(rActor, rData.sStat);
		end
	end

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
		-- Set the training value to 1 (practiced) because we increment the 
		-- training below. This prevents a new skill from instantly being set
		-- to specialized becuase it was initialized at Trained and then incremented
		DB.setValue(matchnode, "training", "number", 1)
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
	if not StringManager.contains({ "might", "speed", "intellect" }, rData.sStat) then
		-- If this is a custom stat, then create the pool if it doesn't exist.
		local node = CharStatManager.getCustomStatPoolNode(rActor, rData.sStat, true);
		
		CharModManager.applyModToTrainingNode(node, "training", rData.sTraining)
		CharModManager.applyModToAssetNode(node, "assets", rData.nAsset);
		CharModManager.applyModToModifierNode(node, "mod", rData.nMod);
		return;
	end

	local charnode = ActorManager.getCreatureNode(rActor);
	local sPath = "stats." .. rData.sStat;
	local statnode = DB.getChild(charnode, sPath)
	if not statnode then
		return;
	end

	local defnode = DB.getChild(statnode, "def");
	if not defnode then
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
		CharArmorManager.modifyArmorMod(rActor, rData.nMod)

		if rData.bSuperArmor then
			CharArmorManager.modifySuperArmor(rActor, rData.nMod);
		end

		CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
		return;
	end

	-- Now we handle the case where there is a damage type, and thus
	-- it should go in the resistances list
	local matchnode;
	for _, resistnode in ipairs(DB.getChildList(resistances)) do
		local sCurDmgType = StringManager.trim(DB.getValue(resistnode, "damagetype", "")):lower();
		local sAmbientArmor = StringManager.trim(DB.getValue(resistnode, "ambient", "")):lower()
		local sSuperArmor = StringManager.trim(DB.getValue(resistnode, "superarmor", "")):lower()

		-- We need to match an existing node based on damage type
		-- PLUS whether that armor applies to ambient and piercing damage
		if sDmgType == sCurDmgType and sAmbientArmor == rData.sAmbient and sSuperArmor == rData.sSuperArmor then
			matchnode = resistnode;
			break;
		end
	end

	-- If there's no matched armor type in the list, then we create one
	if not matchnode then
		matchnode = DB.createChild(resistances);
		DB.setValue(matchnode, "damagetype", "string", rData.sDamageType);
		DB.setValue(matchnode, "ambient", "string", rData.sAmbient)
		DB.setValue(matchnode, "superarmor", "string", rData.sSuperArmor)
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

	CharStatManager.modifyInitiativeTraining(charnode, rData.sTraining)
	CharStatManager.modifyInitiativeMod(charnode, rData.nMod);
	CharStatManager.modifyInitiativeAssets(charnode, rData.nAsset);

	rData.sSummary = "Initiative: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

local _tCustomStatFields = {
	"coststat",
	"stat",
	"defensestat",
	"damagestat",
	"healstat",
}

function applyAbilityModification(rActor, rData, rPromptData)
	-- Add ability to list
	local charnode = ActorManager.getCreatureNode(rActor);
    local abilitylist = DB.createChild(charnode, "abilitylist");
    local abilitynode = DB.createChild(abilitylist);
	local sourcenode = DB.findNode(rData.sLinkRecord);

	if not (abilitynode or sourcenode) then
		return;
	end

    DB.copyNode(sourcenode, abilitynode);

	-- If the ability references custom stat pools, we need to make some edits here
	if DB.getValue(abilitynode, "coststat", "") == "custom" then
		local sCustomStat = DB.getValue(abilitynode, "customstat", "");
		DB.setValue(abilitynode, "coststat", "string", sCustomStat:lower());
	end

	-- Check if actions on the ability reference custom stat pools
	for _, actionnode in ipairs(DB.getChildList(abilitynode, "actions")) do		
		-- For all UI elements that can have custom stats associated with them
		-- Go through and update them with the specified custom stat
		for _, sField in ipairs(_tCustomStatFields) do
			if DB.getValue(actionnode, sField, "") == "custom" then
				DB.setValue(actionnode, sField, "string", DB.getValue(actionnode, sField .. "_custom"):lower());
			end
		end
	end

	-- Save the ability name for later
	local sAbilityName = rData.sSummary or "";
	rData.sSummary = "Ability: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);

	for _, modnode in ipairs(DB.getChildList(sourcenode, "features")) do
		local rMod = CharModManager.getModificationData(modnode)
		rMod.sSource = string.format("%s (Ability)", sAbilityName);
		CharModManager.addModificationToChar(rActor, rMod, rPromptData);
	end

	return abilitynode;
end

function applyRecoveryModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharHealthManager.modifyRecoveryRollMod(rActor, rData.nMod);

	rData.sSummary = "Recovery: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyEdgeModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	local statnode;
	if not StringManager.contains({ "might", "speed", "intellect" }, rData.sStat) then
		statnode = CharStatManager.getCustomStatPoolNode(rActor, rData.sStat, true);
	else 
		statnode = DB.getChild(charnode, "stats." .. rData.sStat);
	end

	if not statnode then
		return;
	end

	CharModManager.applyModToModifierNode(statnode, "edge", rData.nMod);

	rData.sSummary = "Edge: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyEffortModification(rActor, rData)
	local charnode = ActorManager.getCreatureNode(rActor);

	CharModManager.applyModToModifierNode(charnode, "effort.base", rData.nMod);

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
	CharInventoryManager.modifyCypherLimit(rActor, rData.nMod)

	rData.sSummary = "Cypher Limit: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

function applyArmorEffortPenaltyModification(rActor, rData)
	CharArmorManager.modifyEffortPenaltyMod(rActor, rData.nMod);

	rData.sSummary = "Armor: " .. rData.sSummary;
	CharTrackerManager.addToTracker(rActor, rData.sSummary, rData.sSource);
end

-- 0 = inability, 1 - nothing, 2 = trained, 3 = specialized
function applyModToTrainingNode(node, sPath, sTraining)
	if (sTraining or "") == "" then
		return;
	end

	local nCurTraining = DB.getValue(node, sPath, 1);
	local nTraining = TrainingManager.convertTrainingStringToDifficultyModifier(sTraining)

	DB.setValue(node, sPath, "number", TrainingManager.modifyTraining(nCurTraining, nTraining));
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
		if rMod.sStat == "custom" then
			rMod.sStat = DB.getValue(modNode, "custom_stat", ""):lower();
		end
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Skill" then
		rMod.sProperty = "skill"
		rMod.sSkill = DB.getValue(modNode, "skill", "");
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		if rMod.sStat == "custom" then
			rMod.sStat = DB.getValue(modNode, "custom_stat", ""):lower();
		end
		rMod.sTraining = DB.getValue(modNode, "training", ""):lower();
		rMod.nAsset = DB.getValue(modNode, "asset", 0);
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Defense" then
		rMod.sProperty = "defense"
		rMod.sStat = DB.getValue(modNode, "stat", ""):lower();
		if rMod.sStat == "custom" then
			rMod.sStat = DB.getValue(modNode, "custom_stat", ""):lower();
		end
		rMod.sTraining = DB.getValue(modNode, "training", ""):lower();
		rMod.nAsset = DB.getValue(modNode, "asset", 0);
		rMod.nMod = DB.getValue(modNode, "mod", 0);

	elseif rMod.sProperty == "Armor" then
		rMod.sProperty = "armor"
		rMod.nMod = DB.getValue(modNode, "mod", 0);
		rMod.sDamageType = DB.getValue(modNode, "dmgtype", "");
		-- Only apply super armor to untyped damage
		-- Capitalization on "Yes" is necessary
		if rMod.sDamageType == "" then
			rMod.bSuperArmor = DB.getValue(modNode, "superarmor", "") == "Yes";
		else
			rMod.sSuperArmor = StringManager.trim(DB.getValue(modNode, "armor_pierceproof", "")):lower()
			rMod.sAmbient = StringManager.trim(DB.getValue(modNode, "armor_ambient", "")):lower()
		end
		
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
		if rMod.sStat == "custom" then
			rMod.sStat = DB.getValue(modNode, "custom_stat", ""):lower();
		end
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

	elseif rMod.sProperty == "Armor Effort Penalty" then
		rMod.sProperty = "armoreffortpenalty";
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
	elseif rMod.sProperty == "armoreffortpenalty" then
		return CharModManager.getArmorEffortPenaltySummary(rMod);
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

	local sText = string.format("%s%s Armor",
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true),
		sDmgType
	);

	if rMod.bSuperArmor then
		sText = string.format("%s (Immune to Armor piercing)", sText);
	end

	return sText;
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

function getArmorEffortPenaltySummary(rMod)
	if not rMod then
		return "";
	end

	return string.format("%s to Armor Effort Penalty", 
		DiceManager.convertDiceToString({}, rMod.nMod or 0, true)
	);
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
