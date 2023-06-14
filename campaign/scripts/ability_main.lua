function onInit()
	update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	local bAction = usetype.getValue() == "Action";
	local bHasCost = cost.getValue() ~= 0 and coststat.getValue() ~= "-";
	local bShowCost = bAction and (bHasCost or not bReadOnly);
	local bHasType = type.getValue() ~= "";
	local bHasRecharge = period.getValue() ~= "-";
	local bHasUseType = usetype.getValue() ~= "-";

	WindowManager.callSafeControlUpdate(self, "type", bReadOnly, not bHasType and bReadOnly)

	-- Can't use callSafeControlUpdate on these fields because
	-- that function doesn't work on string cyclers
	usetype.setReadOnly(bReadOnly);
	usetype.setVisible(bHasUseType or not bReadOnly);
	usetype_label.setReadOnly(bReadOnly);
	usetype_label.setVisible(bHasUseType or not bReadOnly);

	useequipped.setReadOnly(bReadOnly);
	useequipped.setVisible(bAction and (bHasType or not bReadonly));
	useequipped_label.setReadOnly(bReadOnly);
	useequipped_label.setVisible(bAction and (bHasType or not bReadonly));

	period.setReadOnly(bReadOnly);
	period.setVisible(bAction and (bHasRecharge or not bReadOnly));
	period_label.setReadOnly(bReadOnly);
	period_label.setVisible(bAction and (bHasRecharge or not bReadOnly));

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