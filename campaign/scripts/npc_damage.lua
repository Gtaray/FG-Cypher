-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bParsed = false;
local aDamage = {};

local bDragging = nil;
local hoverAbility = nil;
local clickAbility = nil;

function getActor()
	local wTop = WindowManager.getTopWindow(window);
	local nodeCreature = wTop.getDatabaseNode();
	return ActorManager.resolveActor(nodeCreature);
end

-------------------------------------------------------------------------------
-- EVENTS
-------------------------------------------------------------------------------

function onValueChanged()
	bParsed = false;
end

function onHover(bOnControl)
	if bDragging or bOnControl then
		return;
	end

	hoverAbility = nil;
	setSelectionPosition(0);
end

-- Hilight attack or damage hovered on
function onHoverUpdate(x, y)
	if bDragging then
		return;
	end

	if not bParsed then
		parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);
	hoverAbility = nil;

	for i = 1, #aDamage do
		if aDamage[i].startpos <= nMouseIndex and aDamage[i].endpos > nMouseIndex then
			setCursorPosition(aDamage[i].startpos);
			setSelectionPosition(aDamage[i].endpos);

			hoverAbility = i;			
		end
	end
	
	if hoverAbility then
		setHoverCursor("hand");
	else
		setHoverCursor("arrow");
	end
end

-- Suppress default processing to support dragging
function onClickDown(button, x, y)
	clickAbility = hoverAbility;
	return true;
end

-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(button, x, y)
	setFocus();
	
	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end

function onDoubleClick(x, y)
	if hoverAbility then
		action(nil, aDamage[hoverAbility]);
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if bDragging then
		return true;
	end

	if clickAbility then
		action(draginfo, aDamage[clickAbility]);
		clickAbility = nil;
		bDragging = true;
		return true;
	end
	
	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	bDragging = false;
end

-------------------------------------------------------------------------------
-- ACTION
-------------------------------------------------------------------------------

function action(draginfo, rAction)
	-- Only perform the damage action if this actor is on the CT.
	if not ActorManager.getCTNode(getActor()) then
		return;
	end

	local rActionCopy = UtilityManager.copyDeep(rAction);
	return ActionDamage.performRoll(draginfo, getActor(), rActionCopy);
end

-------------------------------------------------------------------------------
-- PARSING
-------------------------------------------------------------------------------
function parseComponents()
	local sDamage = getValue();

	-- Get rid of some problem characters, and make lowercase
	local sLocal = sDamage:gsub("’", "'");
	sLocal = sLocal:gsub("–", "-");
	sLocal = sLocal:lower();

	-- Parse words
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;\n");
	aDamage = parseDamageLine(aWords)

	for i = 1, #aDamage do
		aDamage[i].startpos = aWordStats[aDamage[i].startindex].startpos
		aDamage[i].endpos = aWordStats[aDamage[i].endindex].endpos
		aDamage[i].startindex = nil;
		aDamage[i].endindex = nil;
	end

	bParsed = true;
end

function parseDamageLine(aWords)
	local damages = {};
	local i = 1;
	while aWords[i] do
		local damage = nil;

		-- Look for defense modification
		if StringManager.isWord(aWords[i], {"damage", "dmg" }) then
			i, damage = parseDamageClause(aWords, i);
		end

		if damage then
			table.insert(damages, damage);
		end

		i = i + 1;
	end

	return damages
end

function parseDamageClause(aWords, i)
	local nDmg = nil;
	local sDmgType = nil;
	local sDmgStat = nil;
	local nIndex = i;
	local nStartIndex = nIndex;
	local nEndIndex = nIndex;

	-- Test the word directly after "damage" to see if it's a stat
	if StringManager.isWord(aWords[nIndex + 1], { "might", "speed", "intellect"}) then
		sDmgStat = aWords[nIndex + 1]
		nEndIndex = nIndex + 1;
	end

	while aWords[nIndex - 1] do
		-- Test to see if the word is a number
		local nDmgTest = tonumber(aWords[nIndex - 1]);

		-- Test the word to see if it's a stat
		if not sDmgStat and StringManager.isWord(aWords[nIndex - 1], { "might", "speed", "intellect"}) then
			sDmgStat = aWords[nIndex - 1]

		-- If it's a number, then its the damage amount
		elseif not nDmg and nDmgTest then
			nDmg = nDmgTest
		
		-- if the word was not a number, and we don't already have a number, then it's a damage type
		elseif not sDmgType then
			sDmgType = aWords[nIndex - 1];
		end

		-- decrement before the bail check because even if we bail
		-- we need to track that we looked at this word
		nIndex = nIndex - 1;

		-- as soon as we have a number, we bail
		-- because the number should be the first thing in the clause
		if nDmg then
			nStartIndex = nIndex;
			break;
		end
	end

	-- if we didn't get a damage number, then we bail with no result
	if not nDmg then
		return i;
	end

	if not sDmgStat then
		sDmgStat = "might";
	end

	local rDmg = {
		nDamage = nDmg,
		sStat = "might",
		sDamageStat = sDmgStat,
		sDamageType = sDmgType,
		startindex = nStartIndex,
		endindex = nEndIndex
	};

	return i, rDmg
end