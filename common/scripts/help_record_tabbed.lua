local tTabs = {};
local tabcontrol;

function onInit()
	if not tabs or not tabs[1] then
		return;
	end

	if target and target[1] then
		tabcontrol = window[target[1]];
	else
		tabcontrol = window.tabs;
	end

	for _,v in pairs(tabs[1].tab) do
		tTabs[v.subwindow[1]] = v.url[1]
	end
end

function onButtonPress()
	local sUrl;
	if tabcontrol then
		local sSubwindow = tabcontrol.getTab(tabcontrol.getIndex());
		sUrl = tTabs[sSubwindow];
	else
		sUrl = default[1]
	end
	
	if sUrl then
		UtilityManager.sendToHelpLink(sUrl);
	end
end