-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = "true" },
	["table"] = { },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
	["init"] = { bUseModStack = "true" },
	["stat"] = { sIcon = "action_roll", sTargeting = "each", bUseModStack = "true" },
	["skill"] = { sIcon = "action_roll", sTargeting = "each", bUseModStack = "true" },
	["defense"] = { sIcon = "action_roll", sTargeting = "each", bUseModStack = "true" },
	["defensevs"] = { sIcon = "action_attack", sTargeting = "all", bUseModStack = true },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = "true" },
	["damage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = "true" },
	["recovery"] = { sIcon = "action_heal" },
	["heal"] = { sIcon = "action_heal", sTargeting = "each", bUseModStack = true },
	["depletion"] = { },
};

targetactions = {
	"stat",
	"skill",
	"defense",
	"defensevs",
	"attack",
	"damage",
	"heal",
	"effect",
};

aRecordOverrides = {
	["ability"] = {
		bExport = true,
		aDataMap = { "ability", "reference.ability" },
		sRecordDisplayClass = "ability",
		sSidebarCategory = "create",
		aCustomFilters = {
			["Type"] = { sField = "type" },
			["Use"] = { sField = "usetype" }
		}
	},
	-- ["type"] = {
	-- 	bExport = true,
	-- 	aDataMap = { "type", "reference.type" },
	-- 	sRecordDisplayClass = "type",
	-- 	sSidebarCategory = "create",
	-- }
}

currencies = { };
currencyDefault = nil;

function onInit()
	for kRecordType,vRecordType in pairs(aRecordOverrides) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
end

function getCharSelectDetailHost(nodeChar)
	local sValue = DB.getValue(nodeChar, "class.descriptor", "") .. " " .. DB.getValue(nodeChar, "class.type", "") .. " who " .. DB.getValue(nodeChar, "class.focus", "");
	sValue = sValue .. " (Tier " .. DB.getValue(nodeChar, "tier", 0) .. ")";
	return sValue;
end

function requestCharSelectDetailClient()
	return "name,class.descriptor,class.type,class.focus,#tier";
end

function receiveCharSelectDetailClient(vDetails)
	return vDetails[1], vDetails[2] .. " " .. vDetails[3] .. " who " .. vDetails[4] .. " (Tier " .. vDetails[5] .. ")";
end

function getCharSelectDetailLocal(nodeLocal)
	local vDetails = {};
	table.insert(vDetails, DB.getValue(nodeLocal, "name", ""));
	table.insert(vDetails, DB.getValue(nodeLocal, "class.descriptor", ""));
	table.insert(vDetails, DB.getValue(nodeLocal, "class.type", ""));
	table.insert(vDetails, DB.getValue(nodeLocal, "class.focus", ""));
	table.insert(vDetails, DB.getValue(nodeLocal, "tier", 0));
	return receiveCharSelectDetailClient(vDetails);
end

function getDistanceUnitsPerGrid()
	return 1;
end
