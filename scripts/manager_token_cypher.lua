-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

healthfields = {
	"hp", 
	"wounds",
	"mightmax",
	"mightpool",
	"speedmax",
	"speedpool",
	"intellectmax",
	"intellectpool"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"stat",
	"skill",
	"atk",
	"attack",
	"def",
	"defense",
	"init",
	"heal",
	"dmg",
	"pierce",
	"recovery",
	"cost",
	"edge",
	"level",
	"asset",
	"maxasset",
	"effort",
	"maxeff"
};

-- Other visible effect types for token widgets
othercomps = {
	-- DIFFICULTY MODIFIER
	["ease"] = "cond_advantage",
	["hinder"] = "cond_disadvantage",
	-- HEALTH / ARMOR
	["dmgo"] = "cond_bleed",
	["regen"] = "cond_regeneration",
	["ignoreimpaired"] = "cond_cover",
	["shield"] = "cond_cover",
	["armor"] = "cond_resistance",
	["superarmor"] = "cond_resistance",
	["immune"] = "cond_immune",
	["vuln"] = "cond_vulnerable",
	-- TRAINING
	["train"] = "cond_advantage",
	["spec"] = "cond_advantage",
	["inability"] = "cond_disadvantage",
	-- ADV / DISADV
	["adv"] = "cond_advantage",
	["grantadv"] = "cond_advantage",
	["disadv"] = "cond_disadvantage",
	["grantdisadv"] = "cond_disadvantage",
};

function onInit()
	TokenManager.addDefaultHealthFeatures(nil, healthfields);

	-- We need to replace this function because the condition icons we use are 
	-- dynamic
	TokenManager.getEffectConditionIcons = getEffectConditionIcons;
	
	TokenManager.addEffectTagIconConditional("if", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("ift", "");
	TokenManager.addEffectTagIconBonus(TokenManagerCypher.bonuscomps);
	TokenManager.addEffectTagIconSimple(TokenManagerCypher.othercomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManagerCypher.parseEffectComp);

	-- TokenManager.setDefaultEffectInfoFunction(getEffectInfoDefault);

	-- This makes sure that when health fields update we update the IF effect icons
	-- for _,sField in ipairs(healthfields) do
	-- 	CombatManager.addCombatantFieldChangeHandler(sField, "onUpdate", TokenManager.updateEffectsField);
	-- end
end

function getEffectConditionIcons()
	return EffectManagerCypher.getConditionIcons();
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	Debug.chat('handleIFEffectTag()', EffectManagerCypher.checkConditional(rActor, nodeEffect, vComp));
	return EffectManagerCypher.checkConditional(rActor, nodeEffect, vComp);
end

function updateConditionsOnTokens()
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		TokenManager.updateEffects(v);
	end
end