-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFlavorDrop(nodeChar, sClass, sRecord)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord);
	if not rAdd then
		return;
	end

	-- Notification
	CharManager.outputUserMessage("char_message_add_flavor", rAdd.sSourceName, rAdd.sCharName);

	CharTrackerManager.addToTracker(
		rAdd.nodeChar, 
		string.format("Flavor: %s", StringManager.capitalize(rAdd.sSourceName)), 
		"Manual");

	-- Add the name and link to the character sheet
	DB.setValue(rAdd.nodeChar, "class.flavor", "string", rAdd.sSourceName);
	DB.setValue(rAdd.nodeChar, "class.flavorlink", "windowreference", rAdd.sSourceClass, DB.getPath(rAdd.nodeSource));
end

function getFlavorNode(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "class.flavorlink");
	return DB.findNode(sRecord);
end

function characterHasFlavor(nodeChar)
	return CharFlavorManager.getFlavorNode(nodeChar) ~= nil;
end

function getFlavorNameForCharacter(nodeChar)
	return DB.getValue(CharFlavorManager.getFlavorNode(nodeChar), "name", "")
end

function getAbilitiesForCharacter(nodeChar, nTier)
	local nodeFlavor = CharFlavorManager.getFlavorNode(nodeChar);
	return CharFlavorManager.getAbilities(nodeFlavor, nTier);
end

function getAbilities(nodeFlavor, nTier)
	if not nodeFlavor then
		return {};
	end

	local aAbilities = {};

	for _, nodeability in ipairs(DB.getChildList(nodeFlavor, "abilities")) do
		if DB.getValue(nodeability, "tier", 0) == nTier then
			local _, sRecord = DB.getValue(nodeability, "link");
			table.insert(aAbilities, {
				nTier = nTier,
				sRecord = sRecord
			});
		end
	end

	return aAbilities;
end

function buildAbilityPromptTable(nodeChar, nTier, rData)
	rData.aFlavorAbilities = {};

	if not CharFlavorManager.characterHasFlavor(nodeChar) then
		return;
	end

	local aFlavorAbilities = CharFlavorManager.getAbilitiesForCharacter(nodeChar, nTier)
	for _, ability in ipairs(aFlavorAbilities) do
		table.insert(rData.aFlavorAbilities, ability);
	end
end

-- We have to get the flavor name separately here (rather than relying on rData)
-- becuase Flavor abilities are tacked on separately as their own thing.
function addAbilities(rData)
	local sFlavorName = CharFlavorManager.getFlavorNameForCharacter(rData.nodeChar);
	for _, sAbility in ipairs(rData.aFlavorAbilities) do
		CharAbilityManager.addAbility(rData.nodeChar, sAbility, sFlavorName, "Flavor", rData);
	end
end