-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local slots = {};
local nMaxSlotRow = 10;
local nDefaultSpacing = 10;
local nSpacing = nDefaultSpacing;

function onInit()
	if maxslotperrow then
		nMaxSlotRow = tonumber(maxslotperrow[1]) or 10;
	end
	if spacing then
		nSpacing = tonumber(spacing[1]) or nDefaultSpacing;
	end
	
	setAnchoredHeight(nSpacing*2);
	setAnchoredWidth(nSpacing);

	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "uses"), "onUpdate", update);
	DB.addHandler(DB.getPath(node, "used"), "onUpdate", update);
	
	self.updateSlots();
end

function onWheel(notches)
	if isReadOnly() then
		return;
	end
	if not Input.isControlPressed() then
		return false;
	end

	self.adjustCounter(notches);
	return true;
end
function onClickDown(button, x, y)
	if isReadOnly() then
		return;
	end
	return true;
end
function onClickRelease(button, x, y)
	if isReadOnly() then
		return;
	end

	local nUses = self.getUses();
	local nMax = nUses;

	local nClickH = math.floor(x / nSpacing) + 1;
	local nClickV;
	if nMax > nMaxSlotRow then
		nClickV	= math.floor(y / nSpacing);
	else
		nClickV = 0;
	end
	local nClick = (nClickV * nMaxSlotRow) + nClickH;

	local nCurrent = self.getUsed();
		
	if nClick > nCurrent then
		self.adjustCounter(1);
	else
		self.adjustCounter(-1);
	end
	
	return true;
end

function update()
	self.updateSlots();
end

function updateSlots()
	-- Construct based on values
	local nUses = self.getUses();
	local nUsed = self.getUsed();
	local nMax = nUses;
	
	if #slots ~= nMax then
		-- Clear
		for k, v in ipairs(slots) do
			v.destroy();
		end
		slots = {};
		
		-- Build the slots, based on the all the spell cast statistics
		for i = 1, nMax do
			local sIcon, sColor;
			if i > nUsed then
				sIcon = stateicons[1].off[1];
			else
				sIcon = stateicons[1].on[1];
			end
			
			if i > nUses then
				sColor = "4FFFFFFF";
			else
				sColor = "FFFFFFFF";
			end

			local nW = (i - 1) % nMaxSlotRow;
			local nH = math.floor((i - 1) / nMaxSlotRow);
			
			local nX = (nSpacing * nW) + math.floor(nSpacing / 2);
			local nY;
			if nMax > nMaxSlotRow then
				nY = (nSpacing * nH) + math.floor(nSpacing / 2);
			else
				nY = (nSpacing * nH) + nSpacing;
			end
			
			slots[i] = addBitmapWidget({ icon = sIcon, color = sColor, position="topleft", x = nX, y = nY });
		end

		-- Determine final width of control based on slots
		if nMax > nMaxSlotRow then
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight((math.floor((nMax - 1) / nMaxSlotRow) + 1) * nSpacing);
		else
			setAnchoredWidth(nMax * nSpacing);
			setAnchoredHeight(nSpacing * 2);
		end
	else
		for i = 1, nMax do
			if i > nUsed then
				slots[i].setBitmap(stateicons[1].off[1]);
			else
				slots[i].setBitmap(stateicons[1].on[1]);
			end
			
			if i > nUses then
				slots[i].setColor("4FFFFFFF");
			else
				slots[i].setColor("FFFFFFFF");
			end
		end
	end
end

function adjustCounter(val_adj)
	local nUsed = self.getUsed() + val_adj;
	local nUses = self.getUses();

	if nUsed > nUses then
		self.setUsed(nUses);
	elseif nUsed < 0 then
		self.setUsed(0);
	else
		self.setUsed(nUsed);
	end
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function canCast()
	return (self.getUsed() < self.getUses());
end

function getUses()
	return DB.getValue(window.getDatabaseNode(), "uses", 0);
end
function setUses(nNewValue)
	return DB.setValue(window.getDatabaseNode(), "uses", "number", nNewValue);
end

function getUsed()
	return DB.getValue(window.getDatabaseNode(), "used", 0);
end
function setUsed(nNewValue)
	return DB.setValue(window.getDatabaseNode(), "used", "number", nNewValue);
end
