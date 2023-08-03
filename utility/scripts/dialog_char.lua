-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fCallback;
local rData;
local bStats;
local bEdge;
local bAbilities;

function setData(data, callback)
	rData = data;
	fCallback = callback;

	bStats = (rData.nFloatingStats or 0) > 0;
	button_stats.setVisible(bStats);
	stats.setVisible(bStats);
	if bStats then
		stats.subwindow.setData(rData.nMight, rData.nSpeed, rData.nIntellect, rData.nFloatingStats);
	end

	bEdge = #(rData.aEdgeOptions or {}) > 0;
	button_edge.setVisible(bEdge);
	edge.setVisible(bEdge)
	if bEdge then
		edge.subwindow.setData(rData.aEdgeOptions);
	end

	bAbilities = #(rData.aAbilityOptions or {}) > 0;
	button_abilities.setVisible(bAbilities)
	abilities.setVisible(bAbilities)
	if bAbilities then
		abilities.subwindow.setData(rData.aAbilityOptions, rData.aFlavorAbilities, rData.nAbilityChoices);
	end

	if bStats then
		self.onNavigation("stats");
	elseif bEdge then
		self.onNavigation("edge");
	elseif bAbilities then
		self.onNavigation("abilities");
	else
		self.onNavigation();
	end

	self.updateAbilities();
end

function updateStats()
	local nMight, nSpeed, nIntellect = stats.subwindow.getData();
	local rEdge = edge.subwindow.getData();

	summary.subwindow.updateMight(rData.nMight, nMight, rEdge["might"]);
	summary.subwindow.updateSpeed(rData.nSpeed, nSpeed, rEdge["speed"]);
	summary.subwindow.updateIntellect(rData.nIntellect, nIntellect, rEdge["intellect"]);

	updateOkButton();
end

function updateAbilities()
	local aAbilities, aFlavorAbilities = abilities.subwindow.getData();
	for _, ability in ipairs(aFlavorAbilities) do
		table.insert(aAbilities, ability);
	end
	summary.subwindow.updateAbilities(aAbilities);

	updateOkButton();
end

function onNavigation(sButton)
	stats.setVisible(sButton == "stats");
	button_stats.setReadOnly(sButton == "stats");

	edge.setVisible(sButton == "edge");
	button_edge.setReadOnly(sButton == "edge");

	abilities.setVisible(sButton == "abilities");
	button_abilities.setReadOnly(sButton == "abilities");
end

function updateOkButton()
	local bConfirm = (not bStats or stats.subwindow.isValid()) and 
					 (not bEdge or edge.subwindow.isValid()) and 
					 (not bAbilities or abilities.subwindow.isValid());


	sub_buttons.subwindow.button_ok.setVisible(bConfirm);
end

function processOK()
	local bClose = true;
	if fCallback then
		if bStats then
			rData.nMight, rData.nSpeed, rData.nIntellect = stats.subwindow.getData();
		end
		
		if bEdge then
			for sStat, nAmount in pairs(edge.subwindow.getData()) do
				for i=1, nAmount, 1 do
					table.insert(rData.aEdgeGiven, sStat);
				end
			end
		end

		if bAbilities then
			local aTypeAbilities, aFlavorAbilities = abilities.subwindow.getData()

			for _, rAbility in ipairs(aTypeAbilities) do
				for i=1, rAbility.multiselect, 1 do
					table.insert(rData.aAbilitiesGiven, DB.getPath(rAbility.node));
				end
			end

			rData.aFlavorAbilities = {}; -- Reset this table so it's empty (we're reusing it)
			for _, rAbility in ipairs(aFlavorAbilities) do
				for i=1, rAbility.multiselect, 1 do
					table.insert(rData.aFlavorAbilities, DB.getPath(rAbility.node));
				end
			end
		end

		if fCallback(rData) then
			bClose = false;
		end
	end
	
	if bClose then
		close();
	end
end

function processCancel()
	close();
end
