function onInit()
	OptionsManager.registerCallback("DMGTYPES", updateDamageTypeOption);
	updateDamageTypeOption();
end
function onClose()
	OptionsManager.unregisterCallback("DMGTYPES", updateDamageTypeOption);
end

function updateDamageTypeOption()
	local bReadOnly = WindowManager.getReadOnlyState(window.getDatabaseNode());

	if window.update then
		window.update();
	else
		self.update(bReadOnly, false);
	end
end

function update(bReadOnly, bForceHide)
	local bDmgTypes = OptionsManagerCypher.replaceArmorWithDamageTypes();
	local bHasValue = getValue() ~= "";
	local bLocalShow = (not bReadOnly or bHasValue) and bDmgTypes and not bForceHide;

	self.setVisible(bLocalShow);
	self.setReadOnly(bReadOnly);

	if window[getName() .. "_label"] then
		window[getName() .. "_label"].setVisible(bLocalShow);
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