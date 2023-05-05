function onInit()
	onAttackTypeChanged();
	onPierceChanged();
end

function onAttackTypeChanged()
	local bWeapon = DB.getValue(getDatabaseNode(), "type", "") == "";
	weapontype_label.setVisible(bWeapon);
	weapontype.setVisible(bWeapon);
end

function onPierceChanged()
	local bPierce = DB.getValue(getDatabaseNode(), "pierce", "") == "yes";
	pierceamount.setVisible(bPierce);
end