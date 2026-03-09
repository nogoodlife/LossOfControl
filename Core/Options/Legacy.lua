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
local Factory  = Options.Factory;
local Handlers = Options.Handlers;

--@natives<lua,wow>
local format = string.format;
local CreateFrame = CreateFrame;

--@class Legacy<gui>
Options.Legacy  = Options.Legacy or {};
local LegacyGUI = Options.Legacy;

function LegacyGUI:Init(config, schema)
	local name   = Engine.Name .. "_OptionsPanel";
	local parent = InterfaceOptionsFramePanelContainer or UIParent;
	local panel  = CreateFrame("Frame", name, parent);
	panel.name   = Util.Localize(schema.nameKey);
	panel:SetAllPoints(parent);
	panel:Hide();

	self.panel = panel;

	local scroll = CreateFrame("ScrollFrame", name .. "Scroll", panel, "UIPanelScrollFrameTemplate");
	scroll:SetPoint("TOPLEFT", 4, -8);
	scroll:SetPoint("BOTTOMRIGHT", -26, 8);

	local child = CreateFrame("Frame");
	child:SetWidth(560);
	child:SetHeight(1);
	scroll:SetScrollChild(child);

	-- Shared handler for both `OnShow`
	local function OnRefresh()
		if not config.isBuilt then
			local width = scroll:GetWidth();
			if width and width > 0 then --[no-op]
				child:SetWidth(width);
			end
			self:Build(child, config, schema);
		end
		self:Refresh(config);
	end

	panel.refresh = OnRefresh;
	panel.okay    = function() end;
	panel.cancel  = function() end;
	panel.default = function() self:ResetDefaults(config, schema); self:Refresh(config); end;

	panel:HookScript("OnShow", OnRefresh);

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel);
	end
end

function LegacyGUI:Build(content, config, schema)
	local layout = Factory:Create(content);
	layout:CreateTitle(Util.Localize(schema.titleKey));
	layout:CreateSubText(format(schema.subtitleFormat, Engine.Notes, Engine.Version, Engine.Author, Engine.Website));

	config.bindings = {};
	local items = Util.FlattenItems(schema.items);

	for i = 1, #items do
		local item    = items[i];
		local handler = Handlers[item.type];

		if handler and handler.Legacy then --[no-op]
			if item.padding then
				layout:NextFlow(item.padding);
			end

			local binding = handler:Legacy(layout, config, item, schema);
			if binding then
				handler:DecorateControl(layout, item, binding);
				config.bindings[#config.bindings + 1] = binding;
			end
		end
	end

	content:SetHeight(layout:GetScrollHeight());
	config.isBuilt = true;
end

function LegacyGUI:Refresh(config)
	if not config.isBuilt then
		return;
	end

	config.isRefreshing = true;
	for i = 1, #config.bindings do
		local bind = config.bindings[i];
		if bind.handler and bind.handler.Refresh then --[no-op]
			bind.handler:Refresh(bind, config);
		end
	end
	config.isRefreshing = false;
end

function LegacyGUI:ResetDefaults(config, schema)
	local db    = config.db;
	local items = Util.FlattenItems(schema.items);

	for i = 1, #items do
		local item = items[i];
		if item.key and item.default ~= nil then
			local tbl = Util.ResolveTable(db, item);
			if tbl then tbl[item.key] = item.default; end
		end
	end
end

function LegacyGUI:Open()
	if not self.panel then return end
	InterfaceOptionsFrame_OpenToCategory(self.panel);
	InterfaceOptionsFrame_OpenToCategory(self.panel);
end