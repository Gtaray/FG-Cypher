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

	bStats = rData.nFloatingStats > 0;
	button_stats.setVisible(bStats);
	stats.setVisible(bStats);
	stats.subwindow.setData(rData.nMight, rData.nSpeed, rData.nIntellect, rData.nFloatingStats);

	bEdge = #(rData.aEdgeOptions) > 0;
	button_edge.setVisible(bEdge);
	edge.setVisible(bEdge)
	edge.subwindow.setData(rData.aEdgeOptions);

	bAbilities = #(rData.aAbilityOptions) > 0 and rData.nAbilityChoices > 0;
	button_abilities.setVisible(bAbilities)
	abilities.setVisible(bAbilities)
	abilities.subwindow.setData(rData.aAbilityOptions, rData.nAbilityChoices);

	if bStats then
		onNavigation("stats");
	elseif bEdge then
		onNavigation("edge");
	elseif bAbilities then
		onNavigation("abilities");
	else
		onNavigation();
	end
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
	local aAbilities = abilities.subwindow.getData();
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
			for _, rAbility in pairs(abilities.subwindow.getData()) do
				for i=1, rAbility.multiselect, 1 do
					table.insert(rData.aAbilitiesGiven, DB.getPath(rAbility.node));
				end
			end
		end

		fCallback(rData);
	end
	
	close();
end

function processCancel()
	close();
end
