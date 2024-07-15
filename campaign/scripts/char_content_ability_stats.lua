function onInit()
	update();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	features.update(bReadOnly);
	features_iedit.setVisibility(not bReadOnly);
	features_iadd.setVisible(not bReadOnly);
end
