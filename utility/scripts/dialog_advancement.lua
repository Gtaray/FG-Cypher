local fCallback
local rData;

local tShortToLong = {}
local tLongToShort = {}

local aTypeAbilities = { }
local aFlavorAbilities = { }
local aFocusAbilities = { }

function onInit()
	tShortToLong["stats"] = Interface.getString("label_advancement_stats");
	tLongToShort[tShortToLong["stats"]] = "stats";

	tShortToLong["edge"] = Interface.getString("label_advancement_edge");
	tLongToShort[tShortToLong["edge"]] = "edge";

	tShortToLong["effort"] = Interface.getString("label_advancement_effort");
	tLongToShort[tShortToLong["effort"]] = "effort";

	tShortToLong["skill"] = Interface.getString("label_advancement_skill");
	tLongToShort[tShortToLong["skill"]] = "skill";

	tShortToLong["ability"] = Interface.getString("label_advancement_ability");
	tLongToShort[tShortToLong["ability"]] = "ability";

	tShortToLong["focus"] = Interface.getString("label_advancement_focus");
	tLongToShort[tShortToLong["focus"]] = "focus";

	tShortToLong["recovery"] = Interface.getString("label_advancement_recovery");
	tLongToShort[tShortToLong["recovery"]] = "recovery";

	tShortToLong["armor"] = Interface.getString("label_advancement_armor");
	tLongToShort[tShortToLong["armor"]] = "armor";
end

function setData(data, callback)
	rData = data;
	fCallback = callback;

	local _, nMight = CharStatManager.getStatPool(rData.nodeChar, "might")
	local _, nSpeed = CharStatManager.getStatPool(rData.nodeChar, "speed")
	local _, nInt = CharStatManager.getStatPool(rData.nodeChar, "intellect")
	stats.subwindow.setData(nMight, nSpeed, nInt, 4);

	edge.subwindow.setData({{ "might", "speed", "intellect" }})

	local nEffort = DB.getValue(rData.nodeChar, "effort", 1);
	effort.subwindow.effort.setValue(string.format(
		Interface.getString("summary_dialog_effort"),
		nEffort,
		nEffort + 1
	));

	local aSkills, aAbilities = buildSkillAdvancementList();
	skill.subwindow.setSkills(aSkills);
	skill.subwindow.addEmptySkill();
	skill.subwindow.setAbilities(aAbilities);

	-- Ability
	aTypeAbilities, aFlavorAbilities = buildAbilityAdvancementList();
	if #aTypeAbilities > 0 then
		abilities.subwindow.setData(aTypeAbilities, aFlavorAbilities, 1);
	end

	-- Focus
	aFocusAbilities = buildFocusAdvancementList();
	if #aFocusAbilities > 0 then
		focus.subwindow.setData(aFocusAbilities, {}, 1);
	end

	local nRecovery = CharHealthManager.getRecoveryRollTotal(rData.nodeChar);
	recovery.subwindow.recovery.setValue(string.format(
		Interface.getString("summary_dialog_recovery"),
		nRecovery,
		nRecovery + 2
	))

	local nArmorPenalty = CharArmorManager.getEffortPenalty(rData.nodeChar)
	armor.subwindow.armor.setValue(string.format(
		Interface.getString("summary_dialog_armor"),
		nArmorPenalty,
		nArmorPenalty - 1
	))

	self.buildAdvancementTypes()
end

function buildAdvancementTypes()
	local tOptions = {}

	if not CharAdvancementManager.hasTakenStatAdvancement(rData.nodeChar) then
		table.insert(tOptions, tShortToLong["stats"])
	end
	if not CharAdvancementManager.hasTakenEdgeAdvancement(rData.nodeChar) then
		table.insert(tOptions, tShortToLong["edge"])
	end
	if not CharAdvancementManager.hasTakenEffortAdvancement(rData.nodeChar) then
		table.insert(tOptions, tShortToLong["effort"])
	end
	if not CharAdvancementManager.hasTakenSkillAdvancement(rData.nodeChar) then
		table.insert(tOptions, tShortToLong["skill"])
	end
	
	type.addItems(tOptions);
	type.setListIndex(1);
end

function rebuildAdvancementEffects()
	rData.sAdvancement = tLongToShort[type.getSelectedValue()];

	local tOptions = {}
	if rData.sAdvancement == "stats" then
		table.insert(tOptions, tShortToLong["stats"]);
	end
	if rData.sAdvancement == "edge" then
		table.insert(tOptions, tShortToLong["edge"]);
	end
	if rData.sAdvancement == "effort" then
		table.insert(tOptions, tShortToLong["effort"]);
	end
	if rData.sAdvancement == "skill" then
		table.insert(tOptions, tShortToLong["skill"]);
	end

	if #aTypeAbilities > 0 then
		table.insert(tOptions, tShortToLong["ability"]);
	end

	if #aFocusAbilities > 0 then
		table.insert(tOptions, tShortToLong["focus"]);
	end

	table.insert(tOptions, tShortToLong["recovery"]);
	table.insert(tOptions, tShortToLong["armor"]);

	effect.clear()
	effect.addItems(tOptions);
	effect.setListIndex(1);
end

function buildSkillAdvancementList()
	local skills = {};
	for _, skillnode in ipairs(DB.getChildList(rData.nodeChar, "skilllist")) do
		local nTraining = DB.getValue(skillnode, "training", 1)
		if nTraining < 3 then -- Don't add skills that are already specialized
			table.insert(skills, {
				sName = DB.getValue(skillnode, "name", ""),
				nTraining = nTraining
			})
		end
	end

	local abilities = {};
	for _, abilitynode in ipairs(DB.getChildList(rData.nodeChar, "abilitylist")) do
		local bInclude = false;
		local nTraining = 1;

		-- Only include abilities that are not linked to items
		local _, sItemLink = DB.getValue(abilitynode, "itemlink");
		if (sItemLink or "") == "" then
			for _, actionnode in ipairs(DB.getChildList(abilitynode, "actions")) do
				-- Only include abilities with stat or attack actions
				local sType = DB.getValue(actionnode, "type", "");

				if sType == "attack" or sType == "stat" then
					-- Only include abilities that are not already specialized
					nTraining = DB.getValue(actionnode, "training", 1);

					if nTraining ~= 3 then
						bInclude = true;
						break;
					end
				end
			end
		end

		if bInclude then
			table.insert(abilities, {
				node = abilitynode,
				sName = DB.getValue(abilitynode, "name", ""),
				nTraining = nTraining
			})
		end
	end

	return skills, abilities;
end

function buildAbilityAdvancementList()
	local nCharTier = CharAdvancementManager.getTier(rData.nodeChar);
	local typenode = CharTypeManager.getTypeNode(rData.nodeChar);
	local focusnode = CharFocusManager.getFocusNode(rData.nodeChar);
	local flavornode = CharFlavorManager.getFlavorNode(rData.nodeChar);

	-- If there's no type node found, then return an empty list
	if not typenode then
		return {}
	end
	
	-- Get abilities the character has
	local tAbilities = {};
	for _, abilitynode in ipairs(DB.getChildList(rData.nodeChar, "abilitylist")) do
		local _, sItemLink = DB.getValue(abilitynode, "itemlink");
		local bMulti = DB.getValue(abilitynode, "selectlimit", "") == "many";

		-- Don't add abilities sourced from items
		-- Also don't add abilities that can be selected multiple times
		if (sItemLink or "") == "" or not bMulti then
			local sName = DB.getValue(abilitynode, "name", "")
			tAbilities[sName:lower()] = true;
		end
	end

	local aAbilities = {};
	for _, abilitynode in ipairs(DB.getChildList(typenode, "abilities")) do
		local nTier = DB.getValue(abilitynode, "tier", 1);
		local sName = DB.getValue(abilitynode, "name", "");
		local _, sRecord = DB.getValue(abilitynode, "link");
		local recordnode = DB.findNode(sRecord);

		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name
		if recordnode and nTier <= nCharTier and not tAbilities[sName:lower()] then
			table.insert(aAbilities, {
				nTier = nTier,
				sRecord = DB.getPath(recordnode)
			});

			-- Add the ability to the overall tracker so that abilities
			-- from a Flavor don't get added twice
			tAbilities[sName:lower()] = true;
		end
	end

	-- Add type swap options from the focus
	for _, abilitynode in ipairs(DB.getChildList(focusnode, "typeswap")) do
		local nTier = DB.getValue(abilitynode, "tier", 1);
		local sName = DB.getValue(abilitynode, "name", "");
		local _, sRecord = DB.getValue(abilitynode, "link");
		local recordnode = DB.findNode(sRecord);

		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name, and the ability is of equal or lower tier
		if recordnode and nTier <= nCharTier and not tAbilities[sName:lower()] then
			table.insert(aAbilities, {
				nTier = nTier,
				sRecord = DB.getPath(recordnode)
			});

			-- Add the ability to the overall tracker so that abilities don't get added twice
			tAbilities[sName:lower()] = true;
		end
	end

	local aFlavorAbilities = {};
	for _, abilitynode in ipairs(DB.getChildList(flavornode, "abilities")) do
		local nTier = DB.getValue(abilitynode, "tier", 1);
		local sName = DB.getValue(abilitynode, "name", "");
		local _, sRecord = DB.getValue(abilitynode, "link");
		local recordnode = DB.findNode(sRecord);

		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name
		if recordnode and nTier <= nCharTier and not tAbilities[sName:lower()] then
			table.insert(aFlavorAbilities, {
				nTier = nTier,
				sRecord = DB.getPath(recordnode)
			});
		end
	end

	return aAbilities, aFlavorAbilities;
end

function buildFocusAdvancementList()
	local aAbilities = {}

	-- If there's no type node found, then return an empty list
	local focusnode = CharFocusManager.getFocusNode(rData.nodeChar);
	if focusnode then
		self.getFocusAbilities(rData.nodeChar, focusnode, aAbilities);
	end

	local focusnode2 = CharFocusManager.getSecondFocusNode(rData.nodeChar);
	if focusnode2 then
		self.getFocusAbilities(rData.nodeChar, focusnode2, aAbilities);
	end
	
	local tAbilities = {};
	for _, abilitynode in ipairs(DB.getChildList(rData.nodeChar, "abilitylist")) do
		local _, sItemLink = DB.getValue(abilitynode, "itemlink");
		local bMulti = DB.getValue(abilitynode, "selectlimit", "") == "many";

		-- Don't add abilities sourced from items
		-- Also don't add abilities that can be selected multiple times
		if (sItemLink or "") == "" or not bMulti then
			local sName = DB.getValue(abilitynode, "name", "")
			tAbilities[sName:lower()] = true;
		end
	end

	local aFinalAbilities = {}
	for _, ability in ipairs(aAbilities) do
		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name
		if not tAbilities[ability.sName:lower()] then
			table.insert(aFinalAbilities, {
				nTier = ability.nTier,
				sRecord = ability.sRecord
			});
		end
	end

	return aFinalAbilities;
end

function getFocusAbilities(charnode, focusnode, aAbilities)
	local nCharTier = CharAdvancementManager.getTier(charnode);

	for _, abilitynode in ipairs(DB.getChildList(focusnode, "abilities")) do
		local nTier = DB.getValue(abilitynode, "tier", 1);
		local sName = DB.getValue(abilitynode, "name", "");
		local _, sRecord = DB.getValue(abilitynode, "link");
		local recordnode = DB.findNode(sRecord);

		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name
		if recordnode and nTier <= nCharTier then
			table.insert(aAbilities, {
				sName = sName,
				nTier = nTier,
				sRecord = DB.getPath(recordnode)
			});
		end
	end

	return aAbilities;
end

function onAdvancementSelected()
	local sAdv = tLongToShort[effect.getSelectedValue()];

	stats.setVisible(sAdv == "stats");
	edge.setVisible(sAdv == "edge");
	effort.setVisible(sAdv == "effort");
	skill.setVisible(sAdv == "skill");
	abilities.setVisible(sAdv == "ability");
	focus.setVisible(sAdv == "focus");
	recovery.setVisible(sAdv == "recovery");
	armor.setVisible(sAdv == "armor");

	rData.sType = sAdv;
end

function processOK()
	if not fCallback then
		return;
	end

	if rData.sType == "stats" then
		rData.nMight, rData.nSpeed, rData.nIntellect = stats.subwindow.getData();
		rData.sMessage = "increase their stat pools";

	elseif rData.sType == "edge" then
		rData.aEdgeGiven = edge.subwindow.getData();
		rData.sMessage = "increase their edge";

	elseif rData.sType == "effort" then
		rData.nMod = 1;
		rData.sMessage = "increase their effort";

	elseif rData.sType == "skill" then
		local rSkillData = skill.subwindow.getData();
		if not rSkillData then
			return
		end
		
		if rSkillData.abilitynode then
			rData.sAbility = rSkillData.sName;
			rData.abilitynode = rSkillData.abilitynode;
		else
			rData.sSkill = rSkillData.sName;
			rData.sTraining = "trained"; -- Hardcode a single step up in training
		end
		rData.sMessage = "gain training in a skill";

	elseif rData.sType == "ability" then
		local aTAbilities, aFAbilities = abilities.subwindow.getData()

		rData.aAbilitiesGiven = {};
		for _, rAbility in ipairs(aTAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Type Ability"
			});
		end
		for _, rAbility in ipairs(aFAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Flavor Ability"
			});
		end
		rData.sMessage = "gain a new ability from their Type";

	elseif rData.sType == "recovery" then
		rData.nMod = 2;
		rData.sMessage = "increase their recoveries by 2";

	elseif rData.sType == "armor" then
		rData.nMod = -1;
		rData.sMessage = "lower their effort penalty from armor by 1";

	elseif rData.sType == "focus" then
		local aFAbilities = focus.subwindow.getData()

		rData.aAbilitiesGiven = {};
		for _, rAbility in ipairs(aFAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Focus Ability"
			});
		end
		rData.sMessage = "gain a new ability from their Focus";
	end

	fCallback(rData);
end