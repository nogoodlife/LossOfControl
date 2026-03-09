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
local Merge = Engine.Util.Merge;
local PRIORITY = Engine.Data.PRIORITY;

----------------------------------------------------------------
--# Static data
----------------------------------------------------------------

local DisplayMode = {
	{ value = 0, key = "OPT_DISPLAY_OFF",   text = "Off" },
	{ value = 1, key = "OPT_DISPLAY_ALERT", text = "Alert only" },
	{ value = 2, key = "OPT_DISPLAY_FULL",  text = "Full display" },
};

local CCTypes = {
	"SILENCE", "STUN", "INCAP", "HORROR", "FEAR",
	"CYCLONE", "BANISH", "POLYMORPH", "SAP", "CHARM", "DISORIENT",
	"FREEZE", "SHACKLE", "SLEEP", "ROOT", "DISARM",-- "SNARE",
};

local CCIcons = {
	SCHOOL_INTERRUPT = "Interface\\Icons\\Ability_Kick",
	STUN             = "Interface\\Icons\\Ability_Rogue_KidneyShot",
	SILENCE          = "Interface\\Icons\\Spell_Shadow_ImpPhaseShift",
	INCAP            = "Interface\\Icons\\Ability_Gouge",
	FEAR             = "Interface\\Icons\\Spell_Shadow_Possession",
	HORROR           = "Interface\\Icons\\Spell_Shadow_PsychicHorrors",
	CYCLONE          = "Interface\\Icons\\Spell_Nature_EarthBind",
	BANISH           = "Interface\\Icons\\Spell_Shadow_Cripple",
	POLYMORPH        = "Interface\\Icons\\Spell_Nature_Polymorph",
	SAP              = "Interface\\Icons\\Ability_Sap",
	CHARM            = "Interface\\Icons\\Spell_Shadow_Charm",
	DISORIENT        = "Interface\\Icons\\Spell_Shadow_MindSteal",
	FREEZE           = "Interface\\Icons\\Spell_Frost_FrostNova",
	SHACKLE          = "Interface\\Icons\\Spell_Nature_Slow",
	SLEEP            = "Interface\\Icons\\Spell_Nature_Sleep",
	ROOT             = "Interface\\Icons\\Spell_Nature_StrangleVines",
	DISARM           = "Interface\\Icons\\Ability_Warrior_Disarm",
	-- SNARE            = "Interface\\Icons\\Spell_Nature_Slow",
};

local CC_ROWS = {
	{ key = "SCHOOL_INTERRUPT", label = "Interrupt", prio = PRIORITY.SCHOOL_INTERRUPT },
	{ key = "STUN",             label = "Stun",      prio = PRIORITY.STUN },
	{ key = "SILENCE",          label = "Silence",   prio = PRIORITY.SILENCE },
	{ key = "INCAP",            label = "Incap",     prio = PRIORITY.INCAP },
	{ key = "FEAR",             label = "Fear",      prio = PRIORITY.FEAR },
	{ key = "HORROR",           label = "Horror",    prio = PRIORITY.HORROR },
	{ key = "CYCLONE",          label = "Cyclone",   prio = PRIORITY.CYCLONE },
	{ key = "BANISH",           label = "Banish",    prio = PRIORITY.BANISH },
	{ key = "POLYMORPH",        label = "Poly",      prio = PRIORITY.POLYMORPH },
	{ key = "SAP",              label = "Sap",       prio = PRIORITY.SAP },
	{ key = "CHARM",            label = "Charm",     prio = PRIORITY.CHARM },
	{ key = "DISORIENT",        label = "Disorient", prio = PRIORITY.DISORIENT },
	{ key = "FREEZE",           label = "Freeze",    prio = PRIORITY.FREEZE },
	{ key = "SHACKLE",          label = "Shackle",   prio = PRIORITY.SHACKLE },
	{ key = "SLEEP",            label = "Sleep",     prio = PRIORITY.SLEEP },
	{ key = "ROOT",             label = "Root",      prio = PRIORITY.ROOT },
	{ key = "DISARM",           label = "Disarm",    prio = PRIORITY.DISARM },
};

----------------------------------------------------------------
--# Item builder
----------------------------------------------------------------

local items = {};
local function Add(item)      items[#items + 1] = item; end

-- Sections
local function Section(text)  Add({ type = "SectionBegin", label = text }) end;
local function EndSection()   Add({ type = "SectionEnd" }) end;
local function Desc(text)     Add({ type = "Description",  label = text }) end;

-- Widgets
local function Checkbox(key, label, default, apply)
	Add({ type = "CheckBox", key = key, label = label, default = default, apply = apply });
end

local function Slider(key, label, min, max, step, default, apply, extra)
	Add(Merge({ type = "Slider", key = key, label = label, min = min, max = max, step = step, default = default, apply = apply }, extra));
end

local function Dropdown(tab, key, label, list, default, deco, extra)
	Add(Merge({ type = "Dropdown", table = tab, key = key, label = label, items = list, default = default, deco = deco }, extra));
end

local function Button(label, apply, extra)
	Add(Merge({ type = "Button", label = label, apply = apply }, extra));
end

----------------------------------------------------------------
--# Build
----------------------------------------------------------------

-- General
Section("OPT_GENERAL");
Checkbox("enabled",      "OPT_ENABLED", true, { target = "frame", method = "UpdateDisplay", args = { false } });
Button("OPT_MOVE_FRAME", { target = "frame", method = "ToggleUnlock"  }, { width = 90, padding = 200 });
Checkbox("soundEnabled", "OPT_SOUND",   true);
Button("OPT_RESET_POS",  { target = "frame", method = "ResetPosition" }, { width = 90, padding = 200 });
EndSection();

-- Visual
Section("OPT_VISUAL");
Slider("frameScale",         "OPT_FRAME_SCALE",   0.5, 3.0, 0.1, 1.0, { target = "frame", method = "ApplyPosition" }, { width = 300, round = "10th" });
Checkbox("showBackground",   "OPT_BACKGROUND",    true, { target = "frame", method = "ApplyVisualOptions" });
Checkbox("showRedLines",     "OPT_RED_LINES",     true, { target = "frame", method = "ApplyVisualOptions" });
Checkbox("enableAnimations", "OPT_ANIMATIONS",    true, { target = "frame", method = "UpdateDisplay", args = { false } });
Checkbox("enablePulse",      "OPT_PULSE",         true);
Checkbox("dynamicTextOn",    "OPT_DYNAMIC_TEXT",  true, { target = "frame", method = "UpdateDisplay", args = { false } }, { tooltip = "OPT_DYNAMIC_TEXT_TIP" });
Checkbox("timerDecimal",     "OPT_TIMER_DECIMAL", true, { target = "frame", method = "UpdateDisplay", args = { false } }, { tooltip = "OPT_TIMER_DECIMAL_TIP" });
EndSection();

-- CC Type Display
Section("OPT_CC_DISPLAY");
Desc("OPT_CC_DESC");
for i = 1, #CC_ROWS do
	local row  = CC_ROWS[i];
	local kind = row.key;
	Dropdown("displayTypeByKind", kind, row.label, DisplayMode, 2, { indent = 8, icon = CCIcons[kind] });
	Slider(kind, "OPT_PRIORITY", 1, 20, 1, row.prio, nil, { table = "priorityByKind", padding = 54, width = 110 });
end
EndSection();

-- Custom Auras
Section("OPT_CUSTOM_AURAS");
Desc("OPT_CUSTOM_AURAS_DESC");
Button("OPT_AURA_MANAGER", { target = "options", method = "OpenAuraManager" }, { width = 120 });
EndSection();

-- Advanced
Section("OPT_ADVANCED");
Checkbox("logUnknown", "OPT_LOG_UNKNOWN", false);
EndSection();

----------------------------------------------------------------
--# Schema
----------------------------------------------------------------

Engine.Modules.Schema = {
	nameKey        = Engine.Title,
	titleKey       = "ADDON_TITLE",
	subtitleFormat = "%s\nVersion: %s\nAuthor: %s\n%s",

	ccTypeChoices  = CCTypes,
	items          = items,
};