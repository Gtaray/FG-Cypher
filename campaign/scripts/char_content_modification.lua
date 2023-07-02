local aProperties = {
	"Stat Pool",
	"Skill",
	"Defense",
	"Armor",
	"Initiative",
	"Ability",
	"Recovery",
	"Edge",
	"Effort",
	"Item",
	"Cypher Limit",
	"Armor Effort Penalty",
}

function onInit()
	update();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		local sProp = property.getSelectedValue();

		if  sClass == "ability" and sProp == "Ability" or 
			sClass == "item" and sProp == "Item" then

			local node = DB.findNode(sRecord)
			if node then
				link.setValue(sClass, sRecord);
				updateLinkName();
			end			
			return true;
		end
	end
end

function getProperties()
	return aProperties;
end

function onPropertyChanged()
	-- Every time we change properties, we want to zero out the link property
	linkname.setValue("");
	link.setValue("", "");
	
	update();
end

function update()
	local sProp = property.getSelectedValue();
	local bEmpty = (sProp or "") == "";
	local bStats = not bEmpty and sProp == "Stat Pool";
	local bSkill = not bEmpty and sProp == "Skill";
	local bDef = not bEmpty and sProp == "Defense";
	local bArmor = not bEmpty and sProp == "Armor";
	local bInit = not bEmpty and sProp == "Initiative";
	local bAbility = not bEmpty and sProp == "Ability";
	local bRec = not bEmpty and sProp == "Recovery";
	local bEdge = not bEmpty and sProp == "Edge";
	local bEffort = not bEmpty and sProp == "Effort";
	local bItem = not bEmpty and sProp == "Item";
	local bCypher = not bEmpty and sProp == "Cypher Limit";
	local bArmorEffortCost = not bEmpty and sProp == "Armor Effort Penalty";

	stats_header.setVisible(bStats);
	skills_header.setVisible(bSkill);
	defense_header.setVisible(bDef);
	armor_header.setVisible(bArmor);
	initiative_header.setVisible(bInit);
	ability_header.setVisible(bAbility);
	recovery_header.setVisible(bRec);
	edge_header.setVisible(bEdge);
	effort_header.setVisible(bEffort);
	item_header.setVisible(bItem);
	cypher_header.setVisible(bCypher);
	armoreffortcost_header.setVisible(bArmorEffortCost);

	updateCombobox("stat", not (bStats or bSkill or bDef or bEdge));
	WindowManager.callSafeControlUpdate(self, "skill", false, not bSkill)
	updateCombobox("training", not (bSkill or bDef or bInit));
	WindowManager.callSafeControlUpdate(self, "asset", false, not (bSkill or bDef or bInit))
	WindowManager.callSafeControlUpdate(self, "mod", false, bEmpty or bAbility or bItem)
	WindowManager.callSafeControlUpdate(self, "dmgtype", false, not bArmor);

	-- Not using WindowManager.callSafeControlUpdate as that function
	-- will hide an empty stringfield if readonly is true. 
	-- I want the stringfield to remain both readonly AND visible
	-- because its empty text has user instructions
	link_label.setVisible(bAbility or bItem)
	linkname.setVisible(bAbility or bItem);
	link.setVisible(bAbility or bItem)

	updateLinkName();
end

function updateLinkName()
	local sClass, sRecord = link.getValue()
	local node = DB.findNode(sRecord);
	if not node then
		return;
	end

	linkname.setValue(DB.getValue(node, "name", ""));
end

function updateCombobox(sControl, bHide)
	if self[sControl] then
		self[sControl].setComboBoxVisible(not bHide);
	end

	local sLabel = sControl .. "_label";
	if self[sLabel] then
		self[sLabel].setVisible(not bHide);
	end
end