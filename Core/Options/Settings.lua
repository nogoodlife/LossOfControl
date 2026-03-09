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
local Options  = Engine.Options;
local Util     = Options.Util;
local Compat   = Options.Compat;
local Handlers = Options.Handlers;

--@class Settings<gui>
Options.Settings  = Options.Settings or {};
local SettingsGUI = Options.Settings;

function SettingsGUI:IsAvailable()
	return Compat:HasModernSettings();
end

function SettingsGUI:Init(config, schema)
	local name = Util.Localize(schema.nameKey);
	local category, layout = Settings.RegisterVerticalLayoutCategory(name);

	local items = Util.FlattenItems(schema.items);

	for i = 1, #items do
		local item    = items[i];
		local handler = Handlers[item.type];
		if handler and handler.Settings then --[no-op]
			handler:Settings(category, layout, config, item, schema);
		end
	end

	Settings.RegisterAddOnCategory(category);
	self.category = category;
end

function SettingsGUI:Open()
	if not self.category or not Settings.OpenToCategory then
		return;
	end

	local categoryID = self.category.GetID and self.category:GetID() or self.category.ID;
	if categoryID then
		Settings.OpenToCategory(categoryID);
	end
end