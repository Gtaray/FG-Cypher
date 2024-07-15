function onInit()
	if super and super.onInit then
		super.onInit()
	end
	registerMenuItem(Interface.getString("char_menu_clear"), "delete", 5)
	self.onValueChanged();
end

function getAttachedLink()
	local sName = getName();
	local sLinkName = sName .. "link";

	return window[sLinkName];
end

function getAttachedLabel()
	if label and label[1] and window[label[1]] then
		return window[label[1]];
	end
end

function onMenuSelection(selection)
	if selection == 5 then
		local cLink = getAttachedLink();
		
		if cLink then
			cLink.setValue("", "");	
		end
		setValue("");
		self.onValueChanged();
	end
end

function onValueChanged()
	if super and super.onValueChanged then
		super.onValueChanged();
	end

	if not hidewhenempty or not hidewhenempty[1] then
		return;
	end

	local cLink = getAttachedLink()
	local bHasLink = cLink and (cLink.getValue() or "") ~= "";
	local bVis = bHasLink or (getValue() or "") ~= "";

	setVisible(bVis);

	local cLabel = getAttachedLabel();
	if cLabel then
		cLabel.setVisible(bVis);
	end

	if not bVis then
		setFocus(false)
	end
end