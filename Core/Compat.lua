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

--@natives<lua>
local type   = type;
local select = select;

--@class Compat<core>
local Compat = {};
Engine.Compat = Compat;

--@constants
Compat.FALLBACK_ICON = "Interface\\Icons\\Spell_Frost_IceShock";
Compat.BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil;

--# issecretvalue() — built-in on Retail clients, nil on older
--- Secret values support (12.x+)
local issecret = issecretvalue or function() return false; end;
Compat.issecret = issecret;

--- Client has addon restrictions
Compat.HasAddonRestrictions = (issecretvalue ~= nil);

--# CLEU
Compat.HasCLEUInfo = (type(CombatLogGetCurrentEventInfo) == "function");

--# GetSpellInfo
--- Returns: name, icon
if C_Spell and C_Spell.GetSpellInfo then
	local _GetSpellInfo = C_Spell.GetSpellInfo;

	function Compat:GetSpellInfo(spellID)
		local spellInfo = _GetSpellInfo(spellID);
		if not spellInfo then
			return;
		end
		return spellInfo.name, spellInfo.iconID;
	end
else
	local _GetSpellInfo = GetSpellInfo;

	function Compat:GetSpellInfo(spellID)
		local name, _, icon = _GetSpellInfo(spellID);
		return name, icon;
	end
end

--# GetUnitDebuff
--- Returns: name, icon, dispelType, duration, expirationTime, spellID
--- Returns: true (only) when aura exists but data is `secret`
--- Returns: nil when no aura at this index.
--- Resolved at load time.
if C_UnitAuras then
	local _GetDebuff = C_UnitAuras.GetDebuffDataByIndex or
		function(unit, index)
			return C_UnitAuras.GetAuraDataByIndex(unit, index, "HARMFUL");
		end

	function Compat:GetUnitDebuff(unit, index)
		local aura = _GetDebuff(unit, index);
		if not aura then
			return;
		end

		local name = aura.name;
		local spellId = aura.spellId;

		if (issecret(spellId) or issecret(name)) then
			return true;
		end

		return name, aura.icon, aura.dispelName, aura.duration, aura.expirationTime, spellId;
	end

elseif UnitAura then
	local _UnitAura = UnitAura;

	function Compat:GetUnitDebuff(unit, index)
		local name, a2, a3, a4, a5, a6, a7, _, _, a10, a11 = _UnitAura(unit, index, "HARMFUL");
		if not name then
			return;
		end

		-- Classic Era/Cata: spellId at position 10 (number)
		if (type(a10) == "number") then
			return name, a2, a4, a5, a6, a10;
		end

		-- WotLK 3.3.5a: spellId at position 11
		return name, a3, a5, a6, a7, a11;
	end
end

--# ParseSpellInterrupt (CLEU Parsing)
--- Returns: destGUID, interruptSpellID, interruptName, interruptedSpellID, interruptedSchool
--- Self-replacing on first call: detects CLEU layout once, then patches itself
function Compat:ParseSpellInterrupt(...)
	if (type(select(3, ...)) == "boolean") then
		-- Retail/Classic CLEU (hideCaster at `arg3`)
		function Compat:ParseSpellInterrupt(...)
			return select(8,  ...), -- destGUID
				   select(12, ...), -- interruptSpellID
				   select(13, ...), -- interruptName
				   select(15, ...), -- interruptedSpellID
				   select(17, ...); -- interruptedSchool
		end
	else
		-- WotLK 3.3.5a CLEU (sourceGUID at `arg3`)
		function Compat:ParseSpellInterrupt(...)
			return select(6,  ...), -- destGUID
				   select(9,  ...), -- interruptSpellID
				   select(10, ...), -- interruptName
				   select(12, ...), -- interruptedSpellID
				   select(14, ...); -- interruptedSchool
		end
	end

	return self:ParseSpellInterrupt(...);
end