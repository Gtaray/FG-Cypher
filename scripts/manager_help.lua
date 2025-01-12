-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _fnOrigPerformMenuHelp;
function onInit()
	_fnOrigPerformMenuHelp = WindowManager.performMenuHelp;
	WindowManager.performMenuHelp = performMenuHelp;
end

function performMenuHelp(c)
	local w = UtilityManager.getTopWindow(c.window);
	local sClass = w.getClass();
	
	if sClass == "power_action_editor" then
		local sType = DB.getValue(w.getDatabaseNode(), "type", "");
		if sType == "stat" then
			Interface.openWindow("url", Interface.getString("help_action_stat"));
		elseif sType == "attack" then
			Interface.openWindow("url", Interface.getString("help_action_attack"));
		elseif sType == "damage" then
			Interface.openWindow("url", Interface.getString("help_action_damage"));
		elseif sType == "heal" then
			Interface.openWindow("url", Interface.getString("help_action_heal"));
		else --if sType == "effect" then
			Interface.openWindow("url", Interface.getString("help_action_effect"));
		end
		return;
	end

	if sClass == "charsheet" then
		local sTab = w.tabs.getActiveTabName();
		if sTab == "skills" then
			Interface.openWindow("url", Interface.getString("help_charsheet_skills"));
		elseif sTab == "inventory" then
			Interface.openWindow("url", Interface.getString("help_charsheet_inventory"));
		elseif sTab == "abilities" then
			Interface.openWindow("url", Interface.getString("help_charsheet_abilities"));
		elseif sTab == "arcs" then
			Interface.openWindow("url", Interface.getString("help_charsheet_arcs"));
		elseif sTab == "notes" then
			Interface.openWindow("url", Interface.getString("help_charsheet_notes"));
		elseif sTab == "actions" then
			Interface.openWindow("url", Interface.getString("help_charsheet_actions"));
		else -- "main"
			Interface.openWindow("url", Interface.getString("help_charsheet_main"));
		end
		return;		
	end

	_fnOrigPerformMenuHelp(c);
end
