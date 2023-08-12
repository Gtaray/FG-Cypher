local fCallback
local rData;

function setData(data, callback)
	rData = data;
	fCallback = callback;

	updateCheckbox("stats", rData.sType == "stats");
	updateCheckbox("edge", rData.sType == "edge");
	updateCheckbox("effort", rData.sType == "effort");
	updateCheckbox("skill", rData.sType == "skill");

	if rData.sType == "stats" then
		stats.subwindow.setData(
			ActorManagerCypher.getStatPool(rData.nodeChar, "might"),
			ActorManagerCypher.getStatPool(rData.nodeChar, "speed"),
			ActorManagerCypher.getStatPool(rData.nodeChar, "intellect"),
			rData.nFloatingStats);
		stats_checkbox.setValue(1);

	elseif rData.sType == "edge" then
		edge.subwindow.setData({{ "might", "speed", "intellect" }})
		edge_checkbox.setValue(1);

	elseif rData.sType == "effort" then
		local nEffort = DB.getValue(rData.nodeChar, "effort", 1);
		effort.subwindow.effort.setValue(string.format(
			Interface.getString("summary_dialog_effort"),
			nEffort,
			nEffort + 1
		));
		effort_checkbox.setValue(1);

	elseif rData.sType == "skill" then
		local aSkills, aAbilities = buildSkillAdvancementList();
		skill.subwindow.setSkills(aSkills);
		skill.subwindow.addEmptySkill();
		skill.subwindow.setAbilities(aAbilities);
		skill_checkbox.setValue(1);
	end

	-- Ability
	local aAbilities, aFlavorAbilities = buildAbilityAdvancementList();
	updateCheckbox("ability", #aAbilities > 0);
	if #aAbilities > 0 then
		abilities.subwindow.setData(aAbilities, aFlavorAbilities, 1);
	end

	-- Focus
	local nTier = ActorManagerCypher.getTier(rData.nodeChar);
	local aFocusAbilities = buildFocusAdvancementList();
	updateCheckbox("focus", nTier >= 3 and #aFocusAbilities > 0);
	if nTier >= 3 and #aFocusAbilities > 0 then
		focus.subwindow.setData(aFocusAbilities, {}, 1);
	end

	local nRecovery = DB.getValue(rData.nodeChar, "recoveryrollmod", 1);
	recovery.subwindow.recovery.setValue(string.format(
		Interface.getString("summary_dialog_recovery"),
		nRecovery,
		nRecovery + 2
	))

	local nArmorPenalty = DB.getValue(rData.nodeChar, "ArmorSpeedPenalty.total", 0);
	armor.subwindow.armor.setValue(string.format(
		Interface.getString("summary_dialog_armor"),
		nArmorPenalty,
		nArmorPenalty - 1
	))

	-- initialize subwindow vis
	onAdvancementSelected(rData.sType, true);
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
		local sTraining = "";

		-- Only include abilities that are not linked to items
		local _, sItemLink = DB.getValue(abilitynode, "itemlink");
		if (sItemLink or "") == "" then
			for _, actionnode in ipairs(DB.getChildList(abilitynode, "actions")) do
				-- Only include abilities with stat or attack actions
				local sType = DB.getValue(actionnode, "type", "");

				if sType == "attack" or sType == "stat" then
					-- Only include abilities that are not already specialized
					sTraining = DB.getValue(actionnode, "training", "");

					if sTraining ~= "specialized" then
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
				nTraining = RollManager.convertTrainingStringToNumber(sTraining)
			})
		end
	end

	return skills, abilities;
end

function buildAbilityAdvancementList()
	local nCharTier = ActorManagerCypher.getTier(rData.nodeChar);
	local typenode = CharTypeManager.getTypeNode(rData.nodeChar);
	local flavornode = CharFlavorManager.getFlavorNode(rData.nodeChar);

	-- If there's no type node found, then return an empty list
	if not typenode then
		return {}
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
			local sName = DB.getValue(abilitynode, "name", "")
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
	local nCharTier = ActorManagerCypher.getTier(rData.nodeChar);
	local _, sFocusNode = DB.getValue(rData.nodeChar, "class.focuslink");
	local focusnode = DB.findNode(sFocusNode or "");

	-- If there's no type node found, then return an empty list
	if not focusnode then
		return {}
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

	local aAbilities = {};
	for _, abilitynode in ipairs(DB.getChildList(focusnode, "abilities")) do
		local nTier = DB.getValue(abilitynode, "tier", 1);
		local sName = DB.getValue(abilitynode, "name", "");
		local _, sRecord = DB.getValue(abilitynode, "link");
		local recordnode = DB.findNode(sRecord);

		-- Only add to the overall list if the player doesn't have an ability
		-- with a matching name
		if recordnode and nTier == 3 and not tAbilities[sName:lower()] then
			table.insert(aAbilities, {
				nTier = nTier,
				sRecord = DB.getPath(recordnode)
			});
		end
	end

	return aAbilities;
end

function updateCheckbox(sType, bShow)
	self[sType .. "_checkbox"].setVisible(bShow);
	self[sType .. "_label"].setVisible(bShow);
end

function uncheckCheckbox(sType)
	self[sType .. "_checkbox"].setValue(0);
end

function onAdvancementSelected(sAdv, bChecked)
	-- Clear out all of the other
	if sAdv ~= "stats" then
		uncheckCheckbox("stats")
	end
	if sAdv ~= "edge" then
		uncheckCheckbox("edge")
	end
	if sAdv ~= "effort" then
		uncheckCheckbox("effort")
	end
	if sAdv ~= "skill" then
		uncheckCheckbox("skill")
	end
	if sAdv ~= "ability" then
		uncheckCheckbox("ability")
	end
	if sAdv ~= "recovery" then
		uncheckCheckbox("recovery")
	end
	if sAdv ~= "armor" then
		uncheckCheckbox("armor")
	end
	if sAdv ~= "focus" then
		uncheckCheckbox("focus")
	end

	stats.setVisible(sAdv == "stats" and bChecked);
	edge.setVisible(sAdv == "edge" and bChecked);
	effort.setVisible(sAdv == "effort" and bChecked);
	skill.setVisible(sAdv == "skill" and bChecked);
	abilities.setVisible(sAdv == "ability" and bChecked);
	focus.setVisible(sAdv == "focus" and bChecked);
	recovery.setVisible(sAdv == "recovery" and bChecked);
	armor.setVisible(sAdv == "armor" and bChecked);

	rData.sType = sAdv;
end

function processOK()
	if not fCallback then
		close();
		return;
	end

	if rData.sType == "stats" then
		rData.nMight, rData.nSpeed, rData.nIntellect = stats.subwindow.getData();
	elseif rData.sType == "edge" then
		rData.aEdgeGiven = edge.subwindow.getData();
	elseif rData.sType == "effort" then
		rData.nMod = 1;
	elseif rData.sType == "skill" then
		local rSkillData = skill.subwindow.getData();
		if rSkillData.abilitynode then
			rData.sAbility = rSkillData.sName;
			rData.abilitynode = rSkillData.abilitynode;
		else
			rData.sSkill = rSkillData.sName;
			rData.sTraining = "trained";
		end
	elseif rData.sType == "ability" then
		local aTypeAbilities, aFlavorAbilities = abilities.subwindow.getData()

		rData.aAbilitiesGiven = {};
		for _, rAbility in ipairs(aTypeAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Type Ability"
			});
		end
		for _, rAbility in ipairs(aFlavorAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Flavor Ability"
			});
		end
	elseif rData.sType == "recovery" then
		rData.nMod = 2;
	elseif rData.sType == "armor" then
		rData.nMod = -1
	elseif rData.sType == "focus" then
		local aFocusAbilities = focus.subwindow.getData()

		rData.aAbilitiesGiven = {};
		for _, rAbility in ipairs(aFocusAbilities) do
			table.insert(rData.aAbilitiesGiven, 
			{
				sRecord = DB.getPath(rAbility.node),
				sSourceType = "Focus Ability"
			});
		end
	end

	fCallback(rData);
	close()
end

function processCancel()
	close();
end