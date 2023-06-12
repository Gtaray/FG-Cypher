function onInit()
	onActionPropertyChanged();
end

function onDrop(x, y, draginfo)
	return WindowManager.handleDropReorder(self, draginfo);
end

function getType()
	return windowlist.window.getType();
end

function onActionPropertyChanged()
	local sProperty = property.getValue()
	local sType = CypherManager.getPropertyType(sProperty);

	local bNumberType = sType == "number";
	-- Only show the value type option when the property is a number value
	-- Can't put cypher level into any other type
	valuesource.setComboBoxVisible(bNumberType);

	lineTwo.setVisible(bNumberType);
	operation.setComboBoxVisible(bNumberType);
	operationsource.setComboBoxVisible(bNumberType);
	operand.setVisible(bNumberType);

	onValueSourceChanged();
end

function onValueSourceChanged()
	local bShowNumberValue = valuesource.getValue() == "fixed value"
	local sType = CypherManager.getPropertyType(property.getValue());

	-- Change the visibility of each of the value fields
	-- such that the only one visible is the one that matches the property type
	value_number.setVisible(bShowNumberValue and sType == "number");
	value_string.setVisible(sType == "string");
	value_training.setComboBoxVisible(sType == "training");
	value_attackrange.setComboBoxVisible(sType == "atkrange")
end