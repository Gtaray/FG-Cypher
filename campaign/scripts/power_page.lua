-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aGroups = {};
local aCharSlots = {};

function onInit()
	self.updatePowerGroups();

	local node = getDatabaseNode();

	DB.addHandler(DB.getPath(node, "powergroup"), "onChildAdded", onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup"), "onChildDeleted", onGroupListChanged);
	DB.addHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", onGroupNameChanged);

	DB.addHandler(DB.getPath(node, "abilitylist.*.group"), "onUpdate", onPowerGroupChanged);

	DB.addHandler(DB.getPath(node, "abilitylist.*.period"), "onUpdate", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.uses"), "onUpdate", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.used"), "onUpdate", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.cost"), "onUpdate", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.coststat"), "onUpdate", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.action"), "onChildAdded", updateAbilityFilters);
	DB.addHandler(DB.getPath(node, "abilitylist.*.action"), "onChildDeleted", updateAbilityFilters);
end
function onClose()
	local node = getDatabaseNode();

	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildAdded", onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup"), "onChildDeleted", onGroupListChanged);
	DB.removeHandler(DB.getPath(node, "powergroup.*.name"), "onUpdate", onGroupNameChanged);

	DB.removeHandler(DB.getPath(node, "abilitylist.*.group"), "onUpdate", onPowerGroupChanged);

	DB.removeHandler(DB.getPath(node, "abilitylist.*.period"), "onUpdate", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.uses"), "onUpdate", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.used"), "onUpdate", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.cost"), "onUpdate", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.coststat"), "onUpdate", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.action"), "onChildAdded", updateAbilityFilters);
	DB.removeHandler(DB.getPath(node, "abilitylist.*.action"), "onChildDeleted", updateAbilityFilters);
end

function onModeChanged()
	self.rebuildGroups();
	self.updateAbilityFilters();
end
function onEditModeChanged()
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			v.onDisplayChanged();
		end
	end
end
function onGroupListChanged()
	self.updatePowerGroups();
end
function onGroupNameChanged(nodeGroupName)
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);

	local nodeParent = DB.getParent(nodeGroupName);
	local sNode = DB.getPath(nodeParent);
	
	local nodeGroup = nil;
	local sOldValue = "";
	for sGroup, vGroup in pairs(aGroups) do
		if vGroup.nodename == sNode then
			nodeGroup = vGroup.node;
			sOldValue = sGroup;
			break;
		end
	end
	if not nodeGroup or sGroup == "" then
		CharPowerManager.resumePowerGroupUpdates(nodeChar);
		return;
	end

	local sNewValue = DB.getValue(nodeParent, "name", "");
	for _,v in pairs(powers.getWindows()) do
		if v.group.getValue() == sOldValue then
			v.group.setValue(sNewValue);
		end
	end

	CharPowerManager.resumePowerGroupUpdates(nodeChar);
	
	self.updatePowerGroups();
end
function onPowerListChanged()
	self.updatePowerGroups();
end
function onPowerGroupChanged(node)
	self.updatePowerGroups();
end

function addPower(bFocus)
	return powers.createWindow(nil, true);
end
function addGroupPower(sGroup)
	local w = powers.createWindow(nil, true);
	w.group.setValue(sGroup);
	return w;
end

--------------------------
-- INDIVIDUAL POWER FILTERING
--------------------------
function updateAbilityFilters()
	local nodeChar = getDatabaseNode();
	-- if CharPowerManager.arePowerUsageUpdatesPaused(nodeChar) then
	-- 	return;
	-- end
	-- CharPowerManager.pausePowerUsageUpdates(nodeChar);

	local sMode = DB.getValue(nodeChar, "powermode", "");

	-- Hide abilities
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() ~= "power_group_header" then
			-- Group stuff isn't really used, but they're here because 5e uses them and
			-- we might want them someday
			local sGroup = v.group.getValue();
			local rGroup = aGroups[sGroup];
			local powernode = v.getDatabaseNode();

			local nUses = DB.getValue(powernode, "uses", 0);
			local bLimitedUses = DB.getValue(powernode, "period", "") ~= "";
			local bHasCost = DB.getValue(powernode, "coststat", "") ~= "" and DB.getValue(powernode, "cost", 0) > 0;
			local bHasActions = DB.getChildCount(powernode, "actions") > 0

			-- Preparation mode shows everything
			local bShow = sMode == "preparation";

			-- Standard mode shows all abilities with costs, usage, or actions
			if sMode == "" then
				bShow = bLimitedUses or bHasCost or bHasActions

			-- Combat mode shows only abilities with limited uses, costs or actions AND there are available uses
			elseif sMode == "combat" then
				local nUsed = DB.getValue(powernode, "used", 0);
				bShow = (bLimitedUses or bHasCost or bHasActions) and (not bLimitedUses or (bLimitedUses and nUsed < nUses))
			end

			if bShow and rGroup then
				rGroup.nShown = (rGroup.nShown or 0) + 1
			end
			v.setFilter(bShow);
		end
	end

	-- Hide headers with no abilities
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			local sGroup = v.group.getValue();
			local rGroup = aGroups[sGroup];	
			local bShow = true;
			
			if rGroup then
				bShow = (rGroup.nShown or 0) > 0;
			end
			
			v.setFilter(bShow);
		end
	end

	powers.applyFilter();
end

--------------------------
-- POWER GROUP DISPLAY
--------------------------
function updatePowerGroups()
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);
	
	-- It's dumb that this is called twice; once at the top and once at the bottom
	-- But it's needed for the list to update correctly when changing power groups
	-- or deleting groups.
	self.rebuildGroups();

	-- Determine all the groups accounted for by current powers
	local aPowerGroups = {};
	for _,nodePower in ipairs(DB.getChildList(getDatabaseNode(), "abilitylist")) do
		local sGroup = DB.getValue(nodePower, "group", "");
		if sGroup ~= "" then
			aPowerGroups[sGroup] = true;
		end
	end
	
	-- Remove the groups that already exist
	for sGroup,_ in pairs(aGroups) do
		if aPowerGroups[sGroup] then
			aPowerGroups[sGroup] = nil;
		end
	end
	
	-- For the remaining power groups, that aren't named
	for k,_ in pairs(aPowerGroups) do
		if not aGroups[k] then
			local nodeGroups = DB.createChild(getDatabaseNode(), "powergroup");
			local nodeNewGroup = DB.createChild(nodeGroups);
			DB.setValue(nodeNewGroup, "name", "string", k);
		end
	end

	self.rebuildGroups();

	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	self.updateHeaders();
end

function updateHeaders()
	local nodeChar = getDatabaseNode();
	if CharPowerManager.arePowerGroupUpdatesPaused(nodeChar) then
		return;
	end
	CharPowerManager.pausePowerGroupUpdates(nodeChar);
	
	-- Close all category headings
	for _,v in pairs(powers.getWindows()) do
		if v.getClass() == "power_group_header" then
			v.close();
		end
	end

	-- Create new category headings
	local aGroupWindows = {};
	for _,nodePower in ipairs(DB.getChildList(getDatabaseNode(), "abilitylist")) do
		local sGroup = self.getWindowSortByNode(nodePower);
		
		if not aGroupWindows[sGroup] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderGroup(aGroups[sGroup], sGroup);
			end
			aGroupWindows[sGroup] = wh;
		end
	end
	
	-- Create empty category headings
	for k,v in pairs(aGroups) do
		if not aGroupWindows[k] then
			local wh = powers.createWindowWithClass("power_group_header");
			if wh then
				wh.setHeaderGroup(v, k, true);
			end
		end
	end

	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	powers.applySort();
end

function onPowerWindowAdded(w)
	
end

--------------------------
-- POWER GROUP DISPLAY
--------------------------
function rebuildGroups()
	aGroups = {};
	aCharSlots = {};
	
	local nodeChar = getDatabaseNode();
	
	for _,v in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		local sGroup = DB.getValue(v, "name", "");
		local rGroup = {};
		rGroup.node = v;
		rGroup.nodename = DB.getPath(v);
		
		aGroups[sGroup] = rGroup;
	end
end

function getWindowSortByNode(node)
	return DB.getValue(node, "group", "");
end

function getWindowSort(w)
	return w.group.getValue();
end

function onSortCompare(w1, w2)
	local vCategory1 = self.getWindowSort(w1);
	local vCategory2 = self.getWindowSort(w2);
	if vCategory1 ~= vCategory2 then
		return vCategory1 > vCategory2;
	end
	
	local bIsHeader1 = (w1.getClass() == "power_group_header");
	local bIsHeader2 = (w2.getClass() == "power_group_header");
	if bIsHeader1 then
		return false;
	elseif bIsHeader2 then
		return true;
	end
	
	local sValue1 = DB.getValue(w1.getDatabaseNode(), "name", ""):lower();
	local sValue2 = DB.getValue(w2.getDatabaseNode(), "name", ""):lower();
	if sValue1 ~= sValue2 then
		return sValue1 > sValue2;
	end
end
