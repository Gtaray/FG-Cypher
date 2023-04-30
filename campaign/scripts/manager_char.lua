-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function updateCyphers(nodeChar)
	local nCypherTotal = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "type", "") == "cypher" then
			nCypherTotal = nCypherTotal + 1;
		end
	end

	DB.setValue(nodeChar, "cypherload", "number", nCypherTotal);
end

--
-- ACTIONS
--

function rest(nodeChar)
	DB.setValue(nodeChar, "recoveryused", "number", 0);
end
