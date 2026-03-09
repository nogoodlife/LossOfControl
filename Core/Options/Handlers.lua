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
local Options = Engine.Options;
local Util    = Options.Util;
local Compat  = Options.Compat;

--@natives<lua>
local pairs = pairs;
local type = type;
local format = string.format;
local tonumber = tonumber;

--@class Handlers<registry>
Options.Handlers = Options.Handlers or {};
local Handlers   = Options.Handlers;

--@internal
local SETTING_PREFIX = Engine.Name:upper() .. "_";
local function SettingID(item)
	local scope = item.table and (item.table:upper() .. "_") or "";
	return SETTING_PREFIX .. scope .. item.key:upper();
end

----------------------------------------------------------------
--# HandlerBase (for all Controls)
----------------------------------------------------------------
local HandlerBase = {};

function HandlerBase:ResolveLabel(item)
	return Util.ResolveText(item);
end

function HandlerBase:Apply(config, item, value, widget)
	Util.InvokeApply(config, item.apply, value, widget);
end

function HandlerBase:SetVar(tbl, item, value)
	Util.SetVar(tbl, item, value);
end

function HandlerBase:ResolveTable(config, itemOrBinding)
	return Util.ResolveTable(config.db, itemOrBinding);
end

function HandlerBase:ReadValue(config, item)
	local tbl = self:ResolveTable(config, item);
	local val = tbl[item.key];
	if val == nil then
		val = item.default;
	end
	return val;
end

function HandlerBase:WriteValue(config, item, value)
	local tbl = self:ResolveTable(config, item);
	tbl[item.key] = value;
end

function HandlerBase:DecorateControl(builder, item, binding)
	if not binding or not binding.widget then
		return;
	end

	local widget = binding.widget;
	local deco   = item.deco or item;

	if deco.indent then
		builder:Indent(widget, deco.indent);
	end
	if deco.icon then
		builder:AttachIcon(widget, deco.icon);
	end
	if deco.backdrop then
		builder:ApplyBackdrop(widget);
	end
end

local function NewHandler(name)
	local handler = setmetatable({ name = name }, { __index = HandlerBase });
	Handlers[name] = handler;
	return handler;
end


----------------------------------------------------------------
--# SectionBegin
----------------------------------------------------------------
local SectionBegin = NewHandler("SectionBegin");

function SectionBegin:Legacy(builder, config, item)
	builder:BeginSection(self:ResolveLabel(item));
end

function SectionBegin:Settings() end;

----------------------------------------------------------------
--# SectionEnd
----------------------------------------------------------------
local SectionEnd = NewHandler("SectionEnd");

function SectionEnd:Legacy(builder)
	builder:EndSection();
end

function SectionEnd:Settings() end;


----------------------------------------------------------------
--# Description
----------------------------------------------------------------
local Description = NewHandler("Description");

function Description:Legacy(builder, config, item)
	local text = self:ResolveLabel(item);
	builder:CreateDescription(text, item.icon);
end

function Description:Settings() end;

----------------------------------------------------------------
--# Header
----------------------------------------------------------------
local Header = NewHandler("Header");

function Header:Legacy(builder, config, item)
	builder:CreateHeader(self:ResolveLabel(item));
end

function Header:Settings() end;

----------------------------------------------------------------
--# CheckBox
----------------------------------------------------------------
local CheckBox = NewHandler("CheckBox");

function CheckBox:Legacy(builder, config, item)
	local label = self:ResolveLabel(item);
	local check = builder:CreateCheckbox(label, item.tooltip);

	check:SetScript("OnClick", function(widget)
		if config.isRefreshing then return end
		local value = widget:GetChecked() and true or false;
		self:SetVar(config.db, item, value);
		self:Apply(config, item, value, widget);
	end);

	return {
		handler = self,
		widget  = check,
		key     = item.key,
		default = item.default,
	};
end

function CheckBox:Settings(category, layout, config, item)
	local db, key = config.db, item.key;
	local setting = Settings.RegisterProxySetting(category, SettingID(item),
		Settings.VarType.Boolean, self:ResolveLabel(item),
		Util.GetBool(db, key, item.default),
		function() return Util.GetBool(db, key, item.default) end,
		function(value)
			self:SetVar(db, item, value and true or false);
			self:Apply(config, item, value);
		end
	);
	Settings.CreateCheckbox(category, setting, item.tooltip);
end

function CheckBox:Refresh(binding, config)
	binding.widget:SetChecked(Util.GetBool(config.db, binding.key, binding.default));
end


----------------------------------------------------------------
--# Slider
----------------------------------------------------------------
local Slider = NewHandler("Slider");

local function ClampSliderValue(item, value)
	value = tonumber(value) or item.min;
	value = Util.Clamp(value, item.min, item.max);
	if item.round == "10th" then
		value = Util.Round10th(value);
	end
	return value;
end

local FORMAT_VALUE = "%.1f";
local function UpdateSliderDisplay(slider, value)
	slider.valueText:SetFormattedText(FORMAT_VALUE, value);
end

function Slider:Legacy(builder, config, item)
	local label  = self:ResolveLabel(item);
	local slider = builder:CreateSlider(label, item.min, item.max, item.step, item.width, item.containerWidth);

	slider:SetScript("OnValueChanged", function(widget, value)
		if config.isRefreshing then return end
		value = ClampSliderValue(item, value);

		self:WriteValue(config, item, value);
		self:Apply(config, item, value, widget);

		UpdateSliderDisplay(widget, value);
	end);

	return {
		handler = self,
		widget  = slider,
		key     = item.key,
		min     = item.min,
		max     = item.max,
		tab     = item.table,
		default = item.default,
	};
end

function Slider:Settings(category, layout, config, item)
	local function GetValue()
		return Util.Clamp(self:ReadValue(config, item), item.min, item.max);
	end

	local function SetValue(value)
		value = ClampSliderValue(item, value);
		self:WriteValue(config, item, value);
		self:Apply(config, item, value);
	end

	local setting = Settings.RegisterProxySetting(
		category,
		SettingID(item),
		Settings.VarType.Number,
		self:ResolveLabel(item),
		GetValue(),
		GetValue,
		SetValue
	);
	Compat:CreateSettingsSlider(category, setting, item.min, item.max, item.step);
end

function Slider:Refresh(binding, config)
	local tbl = binding.handler:ResolveTable(config, binding);
	local value = tbl[binding.key];
	if value == nil then
		value = binding.default or 1.0;
	end

	value = Util.Clamp(value, binding.min, binding.max);
	binding.widget:SetValue(value);

	UpdateSliderDisplay(binding.widget, value);
end

----------------------------------------------------------------
--# Button
----------------------------------------------------------------
local Button = NewHandler("Button");

function Button:Legacy(builder, config, item)
	local label  = self:ResolveLabel(item);
	local button = builder:CreateButton(label, item.width, item.height);

	button:SetScript("OnClick", function(widget)
		if config.isRefreshing then return end
		self:Apply(config, item, true, widget);
	end);

	return { handler = self, widget = button };
end

function Button:Settings(category, layout, config, item)
	if not layout or not CreateSettingsButtonInitializer then
		return;
	end

	local label = self:ResolveLabel(item);
	local init  = CreateSettingsButtonInitializer(label, label,
		function() self:Apply(config, item, true); end,
		item.tooltip, false
	);
	layout:AddInitializer(init);
end


----------------------------------------------------------------
--# Dropdown
----------------------------------------------------------------
local Dropdown = NewHandler("Dropdown");

function Dropdown:Legacy(builder, config, item)
	local label = self:ResolveLabel(item);
	local val   = self:ReadValue(config, item);
	local dd    = builder:CreateDropdown(label, item.width);
	local items = Util.ResolveDropdownItems(item.items);

	dd:SetItems(items);
	dd:SetSelectedValue(val, true);

	local handler = self;
	function dd:OnValueChanged(value)
		if config.isRefreshing then return end
		handler:WriteValue(config, item, value);
		handler:Apply(config, item, value);
	end

	return {
		handler = self,
		widget  = dd,
		items   = items,
		key     = item.key,
		tab     = item.table,
		default = item.default,
	};
end

function Dropdown:Settings(category, layout, config, item)
	local items   = Util.ResolveDropdownItems(item.items);
	if not items[1] then return; end

	local varType = type(items[1].value) == "string" and Settings.VarType.String or Settings.VarType.Number;
	local setting = Settings.RegisterProxySetting(category, SettingID(item), varType,
		self:ResolveLabel(item), self:ReadValue(config, item),
		function() return self:ReadValue(config, item) end,
		function(value)
			self:WriteValue(config, item, value);
			self:Apply(config, item, value);
		end
	);
	Compat:CreateSettingsDropdown(category, setting, items, item.tooltip);
end

function Dropdown:Refresh(binding, config)
	local tbl   = binding.handler:ResolveTable(config, binding);
	local value = tbl[binding.key];
	if value == nil then value = binding.default; end

	if binding.widget:GetSelectedValue() == value then return end
	binding.widget:SetSelectedValue(value, true);
end