function onInit()
	local tEffects = VisionManager.getLightPresetEffects();
	if #tEffects > 0 then
		for _,rEffect in ipairs(tEffects) do
			local w = lights_list.createWindow();
			w.setEffect(rEffect);
		end
	else
		lights_label.setVisible(false);
		lights_list.setVisible(false);
	end
end