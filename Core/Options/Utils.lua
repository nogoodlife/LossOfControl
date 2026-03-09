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
local ipairs = ipairs;
local unpack = unpack;
local type = type;

--@class Util<options>
Engine.Options.Util = Engine.Options.Util or {};
local Util = Engine.Options.Util;

function Util.Localize(key)
	local L = Engine.Locale;
	return (L and L[key]) or key;
end

Util.Clamp = Engine.Util.Clamp;
Util.Round10th = function(value) return Engine.Util.Round(value, 1); end;

function Util.GetBool(storage, key, default)
	local value = storage[key];
	return (value == nil) and default or value;
end

function Util.SetBool(storage, key, value)
	storage[key] = not not value;
end

function Util.SetVar(storage, item, var)
	-- if item.writeToDB ~= false then
	Util.SetBool(storage, item.key, var, item.default);
	-- end
end

function Util.ResolveTable(storage, item)
	local sub = item.table or item.tab;
	return sub and storage[sub] or storage;
end

function Util.ResolveText(item)
	return item.label and Util.Localize(item.label) or item.fallback or item.label or "";
end

function Util.ResolveDropdownItems(items)
	local resolved = {};
	for i = 1, #items do
		local entry = items[i];
		if (type(entry) == "table" and entry.key) then
			resolved[i] = { value = entry.value, text = Util.Localize(entry.key) };
		else
			resolved[i] = entry;
		end
	end
	return resolved;
end

function Util.FlattenItems(items)
	local flat = {};
	for i = 1, #items do
		local entry = items[i];
		if entry.type then
			flat[#flat + 1] = entry;
		else
			for j = 1, #entry do
				flat[#flat + 1] = entry[j];
			end
		end
	end
	return flat;
end


---   { target="frame", method="ApplyVisualOptions" }
---   { target="frame", method="UpdateDisplay", args={false} }
---   { target="frame", method="SetMoverEnabled", passValue=true }
---   { target="engine", field="Debug", passValue=true }
function Util.InvokeApply(config, apply, value, widget)
	if not apply then return; end

	local target = config[apply.target] or config;
	if not target then return; end

	if apply.field then
		target[apply.field] = apply.passValue and value or apply.value;
		return;
	end

	local func = apply.method and target[apply.method];
	if not func then return; end

	if apply.args then
		return func(target, unpack(apply.args));
	elseif apply.passValue then
		return func(target, value, widget);
	end

	return func(target);
end