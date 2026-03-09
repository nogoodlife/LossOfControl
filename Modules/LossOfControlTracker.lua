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

--@import<ns>
local Events = Engine.Events;
local Dispatch = Engine.Dispatcher;
local Compat = Engine.Compat;
local API_LossOfControl = Engine.API.C_LossOfControl;

--@natives<lua,wow>
local pairs = pairs;
local wipe = wipe;
local select = select;
local UnitGUID = UnitGUID;
local GetTime = GetTime;


--@import<data>
local DisplayType = Engine.Data.DisplayType;
local AURA_CC = Engine.Data.AURA_CC;
local INTERRUPT_LOCKOUT = Engine.Data.INTERRUPT_LOCKOUT;
local PRIORITY = Engine.Data.PRIORITY;

--@constants
local MAX_AURAS = 40; -- debuff limit is at 16 for Classic Era and 40 for other, however, we are exiting `if not name`.
local SCHOOL_INTERRUPT = "SCHOOL_INTERRUPT";
local SPELL_INTERRUPT = "SPELL_INTERRUPT";
local PLAYER = "player";


-- Blizzard C_LossOfControl API (Retail only)
local BLoC = (type(_G.C_LossOfControl) == "table") and _G.C_LossOfControl or nil;

--@class LossOfControlTracker<mixin>
local LossOfControlTracker = {
	activeSpells = {},
	trackedExpires = {},
	trackedTypes = {},
};
Engine.Modules.LossOfControlTracker = LossOfControlTracker;

-- All desired events — Events factory will pcall each one.
-- If COMBAT_LOG_EVENT_UNFILTERED is restricted (Retail 12.x+),
-- it will appear in `restricted` and we fall back to Blizzard LoC API.
local TrackerLoCEvents = {
	"UNIT_AURA",
	"COMBAT_LOG_EVENT_UNFILTERED",
	"PLAYER_ENTERING_WORLD",
};

-- Blizzard LoC fallback events for interrupt tracking on Retail
local BlizzardLoCEvents = {
	"LOSS_OF_CONTROL_ADDED",
	"LOSS_OF_CONTROL_UPDATE",
};

local DEFAULT_PRIORITY = 2;
local function AddEffect(db, spellID, locType, icon, duration, expirationTime, lockoutSchool)
	local priority    = db.priorityByKind and db.priorityByKind[locType] or PRIORITY[locType] or DEFAULT_PRIORITY;
	local displayType = db.displayTypeByKind and db.displayTypeByKind[locType] or DisplayType.Full;
	return API_LossOfControl.AddLossOfControlEffect(
		spellID, locType, icon, duration, expirationTime, priority, displayType, lockoutSchool
	);
end

function LossOfControlTracker:Init()
	self.db = Engine.Settings;
	self.guid = UnitGUID(PLAYER);

	local frame, restricted = Events:CreateEventFrame(self, TrackerLoCEvents);
	self.frame = frame;

	-- CLEU restricted? -> fallback to Blizzard LoC API for interrupts
	if restricted and restricted["COMBAT_LOG_EVENT_UNFILTERED"] then
		self.hasCLEU = false;

		if BLoC then
			self.hasBlizzardLoC = true;
			Events:AddEvents(frame, BlizzardLoCEvents);
		else
			self.hasBlizzardLoC = false;
		end
	else
		self.hasCLEU        = true;
		self.hasBlizzardLoC = false;
	end
end

--# -------------------- Event Handlers --------------------

function LossOfControlTracker:UNIT_AURA(unit)
	if unit ~= PLAYER or not self.db.enabled then
		return;
	end
	self:PlayerAuraUpdate();
end

function LossOfControlTracker:COMBAT_LOG_EVENT_UNFILTERED(...)
	if not self.db.enabled then
		return;
	end

	if Compat.HasCLEUInfo then
		self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo());
	else
		self:ProcessCombatLogEvent(...);
	end
end

function LossOfControlTracker:PLAYER_ENTERING_WORLD()
	self.guid = UnitGUID(PLAYER); -- refresh

	if self.db.enabled then
		self:PlayerAuraUpdate();
	end

	Dispatch:FireEvent("LOSS_OF_CONTROL_UPDATE");
end


-- Blizzard LoC events — Retail interrupt tracking fallback.
--- Note: these event names match Blizzard WoW events, NOT our Dispatcher events.
----------------------------------------------------------------
function LossOfControlTracker:LOSS_OF_CONTROL_ADDED()
	if not self.db.enabled then
		return;
	end
	self:ScanBlizzardLoCInterrupts();
end

function LossOfControlTracker:LOSS_OF_CONTROL_UPDATE()
	if not self.hasBlizzardLoC or not self.db.enabled then
		return;
	end
	self:ScanBlizzardLoCInterrupts();
end


--# -------------------- Aura Scanning --------------------

function LossOfControlTracker:PlayerAuraUpdate()
	local db = self.db;
	local customAuras = db.customAuras;

	local activeSpells = self.activeSpells;
	local trackedExpires = self.trackedExpires;
	local trackedTypes = self.trackedTypes;
	wipe(activeSpells);

	local hasNew = false;
	local hasChanges = false;

	for i = 1, MAX_AURAS do
		local name, icon, debuffType, duration, expirationTime, spellID = Compat:GetUnitDebuff(PLAYER, i);

		--[[ GetUnitDebuff returns:
		    nil       - no more auras
		    true      - aura exists but data is secret (skip, continue)
		    name, ... - normal aura data
		]]
		if not name then
			break;
		end
		
		if spellID then
			local locType = customAuras[spellID] or AURA_CC[spellID];
			if locType then
				activeSpells[spellID] = true;

				-- Only if `expirationTime` has changed (new effect or refresh)
				if trackedExpires[spellID] ~= expirationTime then
					trackedExpires[spellID] = expirationTime;
					trackedTypes[spellID] = locType;
					if AddEffect(db, spellID, locType, icon, duration, expirationTime, nil) then
						hasNew = true;
					end
					hasChanges = true;
				end
			else
				-- Potentially unknown CC;
				-- Check debuffType - if it's a CC-like debuff
				if self:IsPotentialCC(debuffType) then
					self:LogUnknownAura(spellID, name, icon);
				end
			end
		end
	end

	-- Remove expired/missing effects
	for spellID in pairs(trackedExpires) do
		if not activeSpells[spellID] then
			trackedExpires[spellID] = nil;
			trackedTypes[spellID] = nil;

			if API_LossOfControl.RemoveBySpellID(spellID) then
				hasChanges = true;
			end
		end
	end

	if hasNew then
		Dispatch:FireEvent("LOSS_OF_CONTROL_ADDED");
	end
	if hasChanges then
		Dispatch:FireEvent("LOSS_OF_CONTROL_UPDATE");
	end
end

--# -------------------- CLEU Interrupt --------------------

function LossOfControlTracker:ProcessCombatLogEvent(...)
	local subEvent = select(2, ...);
	if subEvent ~= SPELL_INTERRUPT then
		return;
	end

	local destGuid, interruptSpellID, interruptName, interruptedSpellID, interruptedSchool = Compat:ParseSpellInterrupt(...);
	if destGuid ~= self.guid then
		return;
	end

	local db = self.db;
	local lockoutDuration = db.customInterrupts[interruptSpellID] or INTERRUPT_LOCKOUT[interruptSpellID];
	if not lockoutDuration then
		if db.logUnknown then
			Engine.Log("|cffffff00[Unknown Interrupt]|r %s (ID: %d)",
				interruptName or "Unknown", interruptSpellID or 0);
		end
		return;
	end

	local now = GetTime();
	local _, iconTexture = Compat:GetSpellInfo(interruptedSpellID);
	iconTexture = iconTexture or Compat.FALLBACK_ICON;
	local lockoutSchool = interruptedSchool or 0;
	local isNew = AddEffect(
		db, interruptedSpellID, SCHOOL_INTERRUPT, iconTexture,
		lockoutDuration, now + lockoutDuration, lockoutSchool
	);
	if isNew then
		Dispatch:FireEvent("LOSS_OF_CONTROL_ADDED");
	end

	Dispatch:FireEvent("LOSS_OF_CONTROL_UPDATE");
end


--# -------------------- Blizzard LoC Interrupt Scanning --------------------
--- Retail fallback: scans Blizzard `C_LossOfControl` for interrupt lockouts
--- when `COMBAT_LOG_EVENT_UNFILTERED` is restricted.

function LossOfControlTracker:ScanBlizzardLoCInterrupts()
	local count = BLoC.GetActiveLossOfControlDataCount();
	if not count or count == 0 then
		return;
	end

	local db = self.db;
	local trackedExpires = self.trackedExpires;
	local trackedTypes = self.trackedTypes;
	local activeSpells = self.activeSpells;
	local issecret = Compat.issecret;
	
	local hasNew = false;
	local hasChanges = false;

	for i = 1, count do
		local data = BLoC.GetActiveLossOfControlData(i);

		if data and data.lockoutSchool and data.lockoutSchool > 0 then
			local spellID        = data.spellID;
			local duration       = data.duration;
			local expirationTime = data.startTime and duration and (data.startTime + duration);

			if spellID and (not issecret(spellID)) and expirationTime then
				activeSpells[spellID] = true;

				if trackedExpires[spellID] ~= expirationTime then
					trackedExpires[spellID] = expirationTime;
					trackedTypes[spellID] = SCHOOL_INTERRUPT;
					if AddEffect(db, spellID, SCHOOL_INTERRUPT, data.iconTexture, duration, expirationTime, data.lockoutSchool) then
						hasNew = true;
					end
					hasChanges = true;
				end
			end
		end
	end

	if hasNew then
		Dispatch:FireEvent("LOSS_OF_CONTROL_ADDED");
	end
	if hasChanges then
		Dispatch:FireEvent("LOSS_OF_CONTROL_UPDATE");
	end
end

--# -------------------- Helpers --------------------

local CC_DEBUFF_TYPES = {
	Magic = true,
	Curse = true,
};

function LossOfControlTracker:IsPotentialCC(debuffType)
	if not debuffType then
		return;
	end
	return CC_DEBUFF_TYPES[debuffType] or false;
end

function LossOfControlTracker:LogUnknownAura(spellID, name, icon)
	local db = self.db;
	if not db.logUnknown or db.unknownSeen[spellID] then
		return;
	end

	db.unknownSeen[spellID] = true;
	Engine.Log("|cffffff00[Unknown CC]|r %s (ID: %d)", name or "?", spellID);
	Engine.Log("Add with '/loc auras' and paste in Spell ID: %d", spellID);
end