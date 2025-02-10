-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFocusDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	CharFocusManager.buildAbilityPromptTable(rAdd.nodeChar, rAdd.nodeSource, 1, rAdd);

	if #(rAdd.aAbilityOptions) > 0 then
		local w = Interface.openWindow("select_dialog_char", "");
		w.setData(rAdd, CharFocusManager.applyTier1);
		return;
	end

	CharFocusManager.applyTier1(rAdd)
end

function hasFocus(nodeChar)
	return DB.getValue(nodeChar, "class.focus.name", "") ~= "";
end
function getFocusNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.focus.link");
	return DB.findNode(sRecord);
end
function getFocusName(nodeChar)
	return DB.getValue(nodeChar, "class.focus.name", "")
end

function hasSecondFocus(nodeChar)
	return DB.getValue(nodeChar, "class.focus2.name", "") ~= "";
end
function getSecondFocusNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.focus2.link");
	return DB.findNode(sRecord);
end
function getSecondFocusName(nodeChar)
	return DB.getValue(nodeChar, "class.focus2.name", "")
end

function buildAbilityPromptTable(nodeChar, nodeFocus, nTier, rData)
	rData.nAbilityChoices = 1;
	rData.aAbilitiesGiven = {};
	rData.aAbilityOptions = {};

	for _, nodeability in ipairs(DB.getChildList(nodeFocus, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == nTier then
			local _, sRecord = DB.getValue(nodeability, "link");
			if DB.getValue(nodeability, "given", 0) == 1 then
				table.insert(rData.aAbilitiesGiven, sRecord);
			else	
				table.insert(rData.aAbilityOptions, {
					nTier = nTier,
					sRecord = sRecord
				});
			end
		end
	end
end

function addTypeSwapAbilities(nodeChar, nodeFocus, nTier, rData)
	if not rData.aAbilityOptions then
		rData.aAbilityOptions = {}
	end

	for _, nodeability in ipairs(DB.getChildList(nodeFocus, "typeswap")) do
		if DB.getValue(nodeability, "tier", 0) <= nTier then
			local _, sRecord = DB.getValue(nodeability, "link");
			table.insert(rData.aAbilityOptions, {
				nTier = nTier,
				sRecord = sRecord
			});
		end
	end
end

function applyTier1(rData)
	-- Notification
	ChatManager.SystemMessageResource("char_message_add_focus", rData.sSourceName, rData.sCharName);

	CharTrackerManager.addToTracker(
		rData.nodeChar, 
		string.format("Focus: %s", StringManager.capitalize(rData.sSourceName)), 
		"Manual");

	local sPath = "class.focus";
	local nOption = tonumber(OptionsManager.getOption("FOCUS_COUNT"));

	-- if we already have a first descriptor, and we're allowed 2, then pick the second
	if CharFocusManager.hasFocus(rData.nodeChar) and nOption == 2 then
		sPath = "class.focus2";
	end
	DB.setValue(rData.nodeChar, sPath .. ".name", "string", rData.sSourceName);
	DB.setValue(rData.nodeChar, sPath .. ".link", "windowreference", rData.sSourceClass, DB.getPath(rData.nodeSource));

	-- Give starting abilities
	CharFocusManager.addAbilities(rData);
end

function addAbilities(rData)
	for _, sAbility in ipairs(rData.aAbilitiesGiven) do
		CharAbilityManager.addAbility(rData.nodeChar, sAbility, rData.sSourceName, "Focus");
	end
end