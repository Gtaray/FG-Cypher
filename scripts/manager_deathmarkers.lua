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
	ImageDeathMarkerManager.setEnabled(true);
	
	ImageDeathMarkerManager.registerGetCreatureTypeFunction(ActorManagerCypher.getCreatureType);

	ImageDeathMarkerManager.registerCreatureTypes(DeathMarkers.creaturetype);
	ImageDeathMarkerManager.setCreatureTypeDefault("construct", "blood_black");
	ImageDeathMarkerManager.setCreatureTypeDefault("plant", "blood_green");
	ImageDeathMarkerManager.setCreatureTypeDefault("undead", "blood_violet");
end