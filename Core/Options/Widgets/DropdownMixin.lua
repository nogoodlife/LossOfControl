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
local Util = Engine.Util;
local Options = Engine.Options;
local Widgets = Options.Widgets;

--@natives<lua,wow>
local pairs = pairs;
local CreateFrame = CreateFrame;
local UIParent = UIParent;

--@constants
local DROPDOWN_MENU_PADING = 6;
local DROPDOWN_LIST_HEIGHT = 18;

--@internal<util>
local DropdownManager = {};
do
	local active;
	local catcher;

	local function GetCatcher()
		if catcher then
			return catcher;
		end

		catcher = CreateFrame("Button", nil, UIParent);
		catcher:SetAllPoints(UIParent);
		catcher:EnableMouse(true);
		catcher:EnableMouseWheel(true);
		catcher:RegisterForClicks("AnyDown");
		catcher:SetFrameStrata("DIALOG");
		catcher:SetScript("OnClick", function()
			if active then active:Close(); end
		end);
		catcher:SetScript("OnMouseWheel", function()
			if active then active:Close(); end
		end);

		catcher:Hide();
		return catcher;
	end

	function DropdownManager.Open(dd)
		if active and active ~= dd then
			active:Close();
		end
		active = dd;

		local cc = GetCatcher();
		cc:Show();

		-- catcher fix level
		local level = (dd.menu:GetFrameLevel() - 1);
		cc:SetFrameLevel(level > 0 and level or 1);

		dd.menu:Show();
	end

	function DropdownManager.Close(dd)
		dd.menu:Hide();
		if active == dd then
			active = nil;
		end

		if catcher then
			catcher:Hide();
		end
	end
end


--@class DropdownMixin<widgets>
local DropdownMixin = {};

function DropdownMixin:SetItems(items)
	self.items = items or {};
	self:LayoutLines();
	self:UpdateText();
end

function DropdownMixin:SetSelectedValue(value, silent)
	self.value = value;
	self:UpdateText();

	if not silent and self.OnValueChanged then
		self:OnValueChanged(value);
	end
end

function DropdownMixin:GetSelectedValue()
	return self.value;
end

-- ----- internal

function DropdownMixin:FindText(value)
	local items = self.items;
	for i = 1, #items do
		if items[i].value == value then
			return items[i].text;
		end
	end
end

function DropdownMixin:UpdateText()
	local txt = self:FindText(self.value);
	self.dropdown.Text:SetText(txt);
end

function DropdownMixin:AcquireLine(i)
	local menu = self.menu;
	local line = menu.lines[i];
	if line then
		return line;
	end

	line = CreateFrame("Button", nil, menu);
	line.Text = line:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	line.Text:SetPoint("LEFT", 8, 0);
	line.Text:SetPoint("RIGHT", -8, 0);
	line.Text:SetJustifyH("LEFT");

	local hlight = line:CreateTexture(nil, "HIGHLIGHT");
	hlight:SetAllPoints();
	Util.SetColorTexture(hlight, 1, 1, 1, 0.2);

	line:SetScript("OnClick", function(button)
		local owner = button.owner;
		owner:SetSelectedValue(button.value);
		owner:Close();
	end);

	menu.lines[i] = line;
	return line;
end

function DropdownMixin:LayoutLines()
	local menu  = self.menu;
	local items = self.items or {};

	for i = 1, #menu.lines do
		menu.lines[i]:Hide();
	end

	local height = DROPDOWN_MENU_PADING * 2;
	for i = 1, #items do
		local line = self:AcquireLine(i);
		line.owner = self;
		line.value = items[i].value;
		line.Text:SetText(items[i].text or "");

		line:SetHeight(DROPDOWN_LIST_HEIGHT);
		line:ClearAllPoints();
		line:SetPoint("TOPLEFT", DROPDOWN_MENU_PADING, -(DROPDOWN_MENU_PADING + (i - 1) * DROPDOWN_LIST_HEIGHT));
		line:SetPoint("RIGHT", -DROPDOWN_MENU_PADING, 0);
		line:Show();

		height = height + DROPDOWN_LIST_HEIGHT;
	end

	menu:SetHeight(height);
end

-- ----- open/close

function DropdownMixin:Open()
	if self.menu:IsShown() then
		return;
	end
	DropdownManager.Open(self);
end

function DropdownMixin:Close()
	if not self.menu:IsShown() then
		return;
	end
	DropdownManager.Close(self);
end

function DropdownMixin:Toggle()
	if self.menu:IsShown() then
		self:Close();
	else
		self:Open();
	end
end

--@export<ns>
Widgets.DropdownMixin = DropdownMixin;