function onInit()
	OptionsManager.registerCallback("DMGTYPES", updateDamageTypeOption);
	updateDamageTypeOption();
end
function onClose()
	OptionsManager.unregisterCallback("DMGTYPES", updateDamageTypeOption);
end

function updateDamageTypeOption()
	local bDmgTypes = OptionsManagerCypher.replaceArmorWithDamageTypes();
	self.setVisible(bDmgTypes)

	local sLabelName = getName() .. "_label";
	if window[sLabelName] then
		window[sLabelName].setVisible(bDmgTypes)
	end
end

function onChar()
	if super and super.onChar then
		super.onChar();
	end
	
	if getCursorPosition() == #getValue() + 1 then
		local sCompletion = StringManager.autoComplete(DamageTypeManager.get(), getValue(), true)
		if sCompletion then
			setValue(getValue() .. sCompletion);
			setSelectionPosition(getCursorPosition() + #sCompletion);
		end
	end
end