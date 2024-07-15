creaturetype = {
	"aberration",
	"beast",
	"celestial",
	"construct",
	"dragon",
	"elemental",
	"fey",
	"fiend",
	"giant",
	"humanoid",
	"monstrosity",
	"ooze",
	"plant",
	"undead",
};

function onInit()
	-- Remove the original handler, then add the modified one
	CombatManager.removeCustomPreDeleteCombatantHandler(ImageDeathMarkerManager.onPreCombatantDelete);
	CombatManager.setCustomPreDeleteCombatantHandler(DeathMarkers.onPreCombatantDelete);

	ImageDeathMarkerManager.setEnabled(true);
	
	ImageDeathMarkerManager.registerGetCreatureTypeFunction(ActorManagerCypher.getCreatureType);

	ImageDeathMarkerManager.registerCreatureTypes(DeathMarkers.creaturetype);
	ImageDeathMarkerManager.setCreatureTypeDefault("construct", "blood_black");
	ImageDeathMarkerManager.setCreatureTypeDefault("plant", "blood_green");
	ImageDeathMarkerManager.setCreatureTypeDefault("undead", "blood_violet");
end

function onPreCombatantDelete(nodeCT)
	if not OptionsManagerCypher.getDeathMarkerOnDelete() then
		return;
	end
	
	if ActorHealthManager.isDyingOrDead(nodeCT) then
		ImageDeathMarkerManager.addMarker(nodeCT);
	end
end