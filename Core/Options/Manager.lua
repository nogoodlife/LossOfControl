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
local Options     = Engine.Options;
local Util        = Engine.Util;
local LegacyGUI   = Options.Legacy;
local SettingsGUI = Options.Settings;

---Initialize
function Options:Init(frameController, schema)
	if not (frameController and schema) then
		return;
	end

	self.config = self:CreateConfig(frameController);
	self.schema = schema;

	if SettingsGUI:IsAvailable() then
		self.mode = "settings";
		SettingsGUI:Init(self.config, schema);
	else
		self.mode = "legacy";
		LegacyGUI:Init(self.config, schema);
	end
end

---Inject
function Options:CreateConfig(frameController)
	return {
		engine       = Engine,
		db           = Engine.Settings,
		locale       = Engine.Locale,
		frame        = frameController,
		options      = self,
		-- LegacyGUI
		isBuilt      = false,
		isRefreshing = false,
		bindings     = nil,
	};
end

function Options:Open()
	if not self.config then
		return;
	end

	if self.mode == "settings" then
		return SettingsGUI:Open(self.config);
	end

	if self.mode == "legacy" then
		return LegacyGUI:Open(self.panel);
	end
end

function Options:OpenAuraManager()
	if not self.config then
		return;
	end

	if not self.dataProvider then
		self.dataProvider = {};
		Util.Mixin(self.dataProvider, self.Widgets.AuraManagerDataMixin);
	end
	self.dataProvider:Init(self.config.db);

	return self.Widgets.AuraManager:Show(
		self.dataProvider,
		self.config.locale,
		self.schema.ccTypeChoices
	);
end