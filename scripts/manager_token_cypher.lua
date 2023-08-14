-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	TokenManager.addDefaultHealthFeatures(nil, {
		"hp", 
		"wounds",
		"mightmax",
		"mightpool",
		"speedmax",
		"speedpool",
		"intellectmax",
		"intellectpool"});
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	-- TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	-- TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	-- TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManagerCypher.parseEffectComp);
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManagerCypher.checkConditional(rActor, nodeEffect, vComp);
end