--[[
 Copyright (c) 2026 s0high
 https://github.com/s0h2x/LossOfControl
    
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
]]

--@class Engine<ns>
local Engine = select(2, ...);

--@natives<lua,wow>
local tinsert = table.insert;
local tremove = table.remove;
local tsort   = table.sort;
local wipe    = wipe;
local GetTime = GetTime;


--@class C_LossOfControl<api>
local C_LossOfControl = {};
Engine.API.C_LossOfControl = C_LossOfControl;


--# -------------------- Internal Helpers --------------------

local activeEffects = {};
local effectIndex = {};

-- Pool
local createFunc = function() return {}; end
local resetFunc  = function(obj) wipe(obj); end
local effectPool = Engine.Util.CreatePool(createFunc, resetFunc);

-- Sorting Auras
local needsSort = false;

local function CompareEffects(a, b)
	if a.priority ~= b.priority then
		return a.priority > b.priority;
	end
	return (a.expirationTime or 0) > (b.expirationTime or 0);
end

local function RebuildIndex()
	wipe(effectIndex);
	for i = 1, #activeEffects do
		local data = activeEffects[i];
		effectIndex[data.spellID] = i;
	end
end

local function SortIfNeeded()
	if needsSort then
		tsort(activeEffects, CompareEffects);
		RebuildIndex();
		needsSort = false;
	end
end


--# -------------------- LossOfControl API --------------------

function C_LossOfControl.GetActiveLossOfControlDataCount()
	return #activeEffects;
end

function C_LossOfControl.GetActiveLossOfControlData(index)
	SortIfNeeded();

	local data = activeEffects[index];
	if not data then
		return nil;
	end

	if data.expirationTime then
		data.timeRemaining = data.expirationTime - GetTime();
	else
		data.timeRemaining = nil;
	end

	return data;
end

function C_LossOfControl.AddLossOfControlEffect(spellID, locType, icon, duration, expirationTime, priority, displayType, lockoutSchool)
	if displayType == 0 then
		return false;
	end

	local now = GetTime();
	local existingIndex = effectIndex[spellID];
	if existingIndex then
		local data = activeEffects[existingIndex];
		local priorityChanged = (data.priority ~= priority);

		data.locType = locType;
		data.iconTexture = icon;
		data.startTime = now;
		data.duration = duration;
		data.expirationTime = expirationTime;
		data.priority = priority;
		data.displayType = displayType;
		data.lockoutSchool = lockoutSchool;

		if priorityChanged then
			needsSort = true;
		end
		return false; -- not added
	end

	local data = effectPool.Acquire();
	data.spellID = spellID;
	data.locType = locType;
	data.iconTexture = icon;
	data.startTime = now;
	data.duration = duration;
	data.expirationTime = expirationTime;
	data.priority = priority;
	data.displayType = displayType;
	data.lockoutSchool = lockoutSchool;

	tinsert(activeEffects, data);
	needsSort = true;

	return true; -- added
end

function C_LossOfControl.RemoveBySpellID(spellID)
	local index = effectIndex[spellID];
	if not index then
		return false;
	end

	local data = tremove(activeEffects, index);
	effectPool.Release(data);
	RebuildIndex();

	return true;
end

function C_LossOfControl.RemoveExpiredEffects()
	local now = GetTime();
	local removed = false;

	for i = #activeEffects, 1, -1 do
		local data = activeEffects[i];
		if data.expirationTime and data.expirationTime <= now then
			tremove(activeEffects, i);
			effectPool.Release(data);
			removed = true;
		end
	end

	if removed then
		RebuildIndex();
	end

	return removed;
end

function C_LossOfControl.ClearAll()
	for i = #activeEffects, 1, -1 do
		effectPool.Release(activeEffects[i]);
	end
	wipe(activeEffects);
	wipe(effectIndex);
	needsSort = false;
end