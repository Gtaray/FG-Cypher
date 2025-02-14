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
	["defensevs"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = true },
	-- There's a little hack I do for attacks because the sTargeting is set to 'all' instead of 'each'
	["attack"] = { sIcon = "action_attack", sTargeting = "all", bUseModStack = "true" },
	["damage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = "true" },
	["recovery"] = { sIcon = "action_heal" },
	["heal"] = { sIcon = "action_heal", sTargeting = "each", bUseModStack = true },
	["depletion"] = { },
	["cost"] = { sIcon = "action_damage" },
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
	"cost",
};

currencies = { };
currencyDefault = nil;

-- Has to be defined before the table
function getAbilityTypeValue(vNode)
	if not vNode then
		return {};
	end
	return StringManager.split(DB.getValue(vNode, "type", ""), ",", true);
end

aRecordOverrides = {
	["ability"] = {
		bExport = true,
		aDataMap = { "ability", "reference.ability" },
		sRecordDisplayClass = "ability",
		sSidebarCategory = "create",
		aCustomFilters = {
			["Type"] = { sField = "type", fGetValue = getAbilityTypeValue },
			["Use"] = { sField = "usetype" }
		}
	},
	["ancestry"] = {
		bExport = true,
		aDataMap = { "ancestry", "reference.ancestry" },
		sRecordDisplayClass = "ancestry",
		sSidebarCategory = "create",
	},
	["descriptor"] = {
		bExport = true,
		aDataMap = { "descriptor", "reference.descriptor" },
		sRecordDisplayClass = "descriptor",
		sSidebarCategory = "create",
	},
	["flavor"] = {
		bExport = true,
		aDataMap = { "flavor", "reference.flavor" },
		sRecordDisplayClass = "flavor",
		sSidebarCategory = "create",
	},
	["focus"] = {
		bExport = true,
		aDataMap = { "focus", "reference.focus" },
		sRecordDisplayClass = "focus",
		sSidebarCategory = "create",
	},
	["type"] = {
		bExport = true,
		aDataMap = { "type", "reference.type" },
		sRecordDisplayClass = "type",
		sSidebarCategory = "create",
	},
}

function onInit()
	LibraryData.overrideRecordTypes(aRecordOverrides);
	CombatListManager.registerStandardInitSupport();
end

function getCharSelectDetailHost(nodeChar)
	return CharManager.getCharacterStatement(nodeChar);
end

function requestCharSelectDetailClient()
	return "name,class.descriptor.name,class.descriptor2.name,class.ancestry.name,class.ancestry2.name,class.type.name,class.focus.name,class.focus2.name,#advancement.tier";
end

function receiveCharSelectDetailClient(vDetails)
	return CharManager.buildCharacterStatement(vDetails[1],vDetails[2],vDetails[3],vDetails[4],vDetails[5],vDetails[6],vDetails[7],vDetails[8],vDetails[9]);
end

function getDistanceUnitsPerGrid()
	return 5;
end
