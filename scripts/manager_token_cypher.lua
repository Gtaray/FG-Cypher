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
end
