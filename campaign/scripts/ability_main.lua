function onInit()
	update();
end

function update()
	local node = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(node);
	local bAction = usetype.getValue() == "Action";
	local bHasCost = cost.getValue() ~= 0 and coststat.getValue() ~= "-";
	local bShowCost = bAction and (bHasCost or not bReadOnly);
	local bHasType = type.getValue() ~= "";
	local bHasRecharge = period.getValue() ~= "-";
	local bHasUseType = usetype.getValue() ~= "-";
	local bRef = StringManager.startsWith(DB.getPath(node), "ability");

	WindowManager.callSafeControlUpdate(self, "type", bReadOnly, not bHasType and bReadOnly)

	-- Can't use callSafeControlUpdate on these fields because
	-- that function doesn't work on string cyclers
	usetype.setReadOnly(bReadOnly);
	usetype.setVisible(bHasUseType or not bReadOnly);
	usetype_label.setVisible(bHasUseType or not bReadOnly);
	selectlimit.setReadOnly(bReadOnly);
	selectlimit.setVisible(bRef)
	selectlimit_label.setVisible(bRef)

	useequipped.setReadOnly(bReadOnly);
	useequipped.setVisible(bAction and (bHasType or not bReadonly));
	useequipped_label.setVisible(bAction and (bHasType or not bReadonly));

	period.setReadOnly(bReadOnly);
	period.setVisible(bAction and (bHasRecharge or not bReadOnly));
	period_label.setVisible(bAction and (bHasRecharge or not bReadOnly));
	WindowManager.callSafeControlUpdate(self, "uses", bReadOnly);
	WindowManager.setControlVisibleWithLabel(self, "uses", bHasRecharge);

	header_cost.setVisible(bShowCost);
	costtext1.setVisible(bShowCost);
	cost.setReadOnly(bReadOnly);
	cost.setVisible(bShowCost);
	label_cost.setVisible(bShowCost);
	costtext2.setVisible(bShowCost);
	label_coststat.setVisible(bShowCost);
	coststat.setVisible(bShowCost);
	coststat.setReadOnly(bReadOnly);
	costtext3.setVisible(bShowCost);
	
	ftdesc.setReadOnly(bReadOnly);
end